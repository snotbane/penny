
## Responsible for translating and validating a single file into workable statements.
class_name PennyParser extends Object

const RX_LF = "\\n"

class Token:
	enum {
		INDENTATION,		## NOT ADDED TO STATEMENTS
		VALUE_STRING,		## Multiline
		ARRAY_CAPS,
		PARENTHESIS_CAPS,
		VALUE_COLOR,
		VALUE_NUMBER,
		VALUE_BOOLEAN,
		OPERATOR_GENERIC,
		OPERATOR_BOOLEAN,
		OPERATOR_NUMERIC,
		OPERATOR_NUMERIC_EQUALITY,
		COMMENT,
		ASSIGNMENT,
		KEYWORD,
		IDENTIFIER,
		TERMINATOR,			## NOT ADDED TO STATEMENTS
		WHITESPACE,			## NOT ADDED TO STATEMENTS
	}

	static var PATTERNS = [
		RegEx.create_from_string("(?m)^\\t+"),
		RegEx.create_from_string("(?s)(\"\"\"|\"|'''|'|```|`).*?\\1"),
		RegEx.create_from_string("(?s)[\\[\\]]|,(?=.*\\])"),
		RegEx.create_from_string("(?s)[\\(\\)]"),
		RegEx.create_from_string("(?i)#([0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{3,4})(?![0-9a-f])"),
		RegEx.create_from_string("(?<=[^\\d\\.])(\\d+\\.\\d+|\\.\\d+|\\d+\\.|\\d+)(?=[^\\d\\.])"),
		RegEx.create_from_string("\\b(true|True|TRUE|false|False|FALSE)\\b"),
		RegEx.create_from_string("(\\b\\.\\b)|==|!="),
		RegEx.create_from_string("!|&&|\\|\\||(\\b(and|nand|or|nor|not)\\b)"),
		RegEx.create_from_string("\\+|-|\\*|/|%|&|\\|"),
		RegEx.create_from_string(">|<|<=|>="),
		RegEx.create_from_string("(([#/])\\*(.|\\n)*?(\\*\\2|$))|((#|\\/\\/).*(?=\\n))"),
		RegEx.create_from_string("\\+=|-=|\\*=|/=|=|is"),
		RegEx.create_from_string("\\b(dec|dive|elif|else|if|filter|jump|label|menu|object|pass|print|return|rise|suspend)\\b"),
		RegEx.create_from_string("[a-zA-Z_]\\w*"),
		RegEx.create_from_string("(?m)[:;]|((?<=[^\\n:;])$\\n)"),
		RegEx.create_from_string("(?m)[ \\n]+|(?<!^|\\t)\\t+"),
	]

	static var RX_BOOLEAN_OPERATOR = RegEx.create_from_string("((\\b\\.\\b)|==|!=|!|&&|\\|\\|)|(\\b(and|nand|or|nor|not)\\b)")
	static var RX_STRING_TRIM = RegEx.create_from_string("(?s)(?<=(\"\"\"|\"|'''|'|```|`)).*?(?=\\1)")

	var type : int
	var line : int
	var col : int
	var cur : int
	var value : String

	var col_end : int :
		get: return col + value.length()

	var belongs_in_expression_variant : bool :
		get: return type >= VALUE_STRING && type <= OPERATOR_NUMERIC_EQUALITY

	var belongs_in_expression_boolean : bool :
		get: return type == PARENTHESIS_CAPS || ( type >= VALUE_BOOLEAN && type <= OPERATOR_BOOLEAN )

	func _init(_type: int, _line: int, _col: int, _cur: int, _value: String) -> void:
		type = _type
		line = _line
		col = _col
		cur = _cur
		value = _value

	func _to_string() -> String:
		return "ln %s cl %s type %s : %s" % [line, col, type, value]

class Statement:

	enum {
		INVALID,

		# keyword standalone, require 0 parameters
		INIT,
		PASS,
		RISE,

		# keyword, optional 1 expression
		PRINT,
		RETURN,

		# keyword, require 1 identifier
		DIVE,
		LABEL,
		JUMP,

		# block require indentation
		BRANCH,			## IMPLICIT
		CONDITION,
		DECORATION,
		FILTER,
		MENU,
		OBJECT_MANIPULATE,

		## Miscellaneous
		ASSIGN,			## IMPLICIT
		MESSAGE,		## IMPLICIT
	}

	var type : int
	var line : int
	var depth : int
	var tokens : Array[Token]

	var is_blocking : bool :
		get:
			match type:
				MESSAGE, MENU: return true
			return false

	var is_recorded : bool :
		get:
			match type:
				ASSIGN: return true
			return false

	func _init(_line: int, _depth: int) -> void:
		line = _line
		depth = _depth

	func debug_string() -> String:
		return "ln %s dp %s type %s : %s" % [line, depth, type, to_string()]

	func _to_string() -> String:
		var result := ""
		for i in tokens:
			result += i.value + " "
		return result.substr(0, result.length() - 1)

	func add_token(token: Token) -> void:
		tokens.append(token)

	func validate() -> bool:
		if tokens.size() == 0:
			PennyException.push_error(PennyException.PARSE_ERROR_UNCAUGHT_VALIDATION, [self])
			return false

		match tokens[0].type:
			Token.VALUE_STRING:
				if tokens.size() == 1:
					return validate_message_extension(MESSAGE)
				elif tokens.size() == 2:
					return validate_message_direct(MESSAGE)
			Token.KEYWORD:
				match tokens[0].value:
					"init": return validate_keyword_standalone(INIT)
					"pass": return validate_keyword_standalone(PASS)
					"rise": return validate_keyword_standalone(RISE)
					"print": return validate_keyword_with_optional_expression(PRINT)
					"return": return validate_keyword_with_optional_expression(RETURN)
					"dive": return validate_keyword_with_required_expression(DIVE)
					"label": return validate_keyword_with_required_expression(LABEL)
					"jump": return validate_keyword_with_required_expression(JUMP)
					"elif", "else", "if": return validate_conditional(CONDITION)
					"object": return validate_keyword_standalone_with_required_block(OBJECT_MANIPULATE)
					"filter": return validate_keyword_standalone_with_required_block(FILTER)
			Token.IDENTIFIER:
				if tokens.size() == 1:
					return validate_object_manipulation(OBJECT_MANIPULATE)
				match tokens[1].type:
					Token.VALUE_STRING:
						return validate_message_direct(MESSAGE)
					Token.ASSIGNMENT:
						return validate_object_assignment(ASSIGN)

		PennyException.push_error(PennyException.PARSE_ERROR_UNCAUGHT_VALIDATION, [self])
		return false

	func validate_keyword_standalone(expect: int) -> bool:
		type = expect
		if tokens.size() == 1:
			return true
		else:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[1]])
			return false

	func validate_keyword_with_optional_expression(expect: int) -> bool:
		type = expect
		var expr := tokens
		expr.pop_front()
		if expr.size() == 0:
			return true
		return validate_expression(self, expr)

	func validate_keyword_with_required_expression(expect: int) -> bool:
		type = expect
		if tokens.size() == 1:
			PennyException.push_error(PennyException.PARSE_ERROR_EXPECTED_IDENTIFIER, [line, tokens[0].col_end, tokens[0].value])
			return false
		if tokens.size() > 2:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[2]])
			return false
		if tokens[1].type != Token.IDENTIFIER:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[1]])
			return false
		return true

	func validate_keyword_standalone_with_required_block(expect: int) -> bool:
		return validate_keyword_standalone(expect)

	func validate_object_manipulation(expect: int) -> bool:
		type = expect
		return true

	func validate_object_assignment(expect: int) -> bool:
		type = expect
		if tokens[1].value == 'is':
			if tokens.size() > 3:
				PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[3]])
				return false
			if tokens[2].type != Token.IDENTIFIER && tokens[2].value != 'object':
				PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[2]])
				return false
			return true
		else:
			var expr := tokens
			expr.pop_front()
			expr.pop_front()
			return validate_expression(self, expr)

	func validate_message_direct(expect: int) -> bool:
		type = expect
		if tokens.size() > 2:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[2]])
			return false
		if tokens[0].type != Token.IDENTIFIER && tokens[0].type != Token.VALUE_STRING:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[0]])
			return false
		if tokens[1].type != Token.VALUE_STRING:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[1]])
			return false
		return true

	func validate_message_extension(expect: int) -> bool:
		type = expect
		if tokens.size() != 1:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[1]])
			return false
		return true

	func validate_conditional(expect: int) -> bool:
		type = expect
		var expr := tokens
		expr.pop_front()
		return validate_expression(self, expr)


	static func validate_expression(ref: Statement, _tokens: Array[Token]) -> bool:
		if _tokens.size() == 0:
			PennyException.push_error(PennyException.PARSE_ERROR_EXPECTED_EXPRESSION, [ref.line, 0, ref._tokens[0].value])
			return false
		for i in _tokens.size():
			if not _tokens[i].belongs_in_expression_variant:
				PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [_tokens[i]])
				return false
		return true

	static func validate_boolean_expression(ref: Statement, _tokens: Array[Token]) -> bool:
		if _tokens.size() == 0:
			PennyException.push_error(PennyException.PARSE_ERROR_EXPECTED_EXPRESSION, [ref.line, 0, ref._tokens[0].value])
			return false
		for i in _tokens.size():
			if not _tokens[i].belongs_in_expression_variant:
				PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [_tokens[i]])
				return false
		return true

static var rx_line_col := RegEx.create_from_string(RX_LF)
static var _cursor : int = 0
static var cursor : int :
	get : return _cursor
	set (value) :
		_cursor = value

		var rm_lf := rx_line_col.search_all(raw_data, 0, _cursor)

		line = rm_lf.size() + 1

		col = _cursor + 1
		if line != 1:
			col -= rm_lf[line - 2].get_end()

static var line : int = 0
static var col : int = 0

var file : FileAccess
var	errors : Array[String]
static var raw_data : String

func _init(_file: FileAccess) -> void:
	file = _file

	print("***			Parsing file \"" + file.get_path() + "\"...")
	PennyException.active_file_path = file.get_path()

	raw_data = file.get_as_text(true)

	## Tokens
	var tokens := tokenize()
	# print("***				TOKENS:")
	# for i in tokens:
	# 	print(i)

	## Statement Creation
	var statements := statementize(tokens)
	print("***				STATEMENTS:")
	for i in statements:
		print(i.debug_string())

	## Statement Validations
	print("***				VALIDATIONS:")
	var all_valid := validate_statements(statements)

	if all_valid:
		export_statements(statements)
	else:
		Penny.valid = false

	print("***			Finished parsing file \"" + file.get_path() + "\".")

func tokenize() -> Array[Token]:
	var result : Array[Token]

	## If this gets stuck in a loop, Token.PATTERNS has a regex pattern that matches with something of 0 length, e.g. ".*"
	cursor = 0
	while cursor < raw_data.length():
		var match_found = false

		for i in Token.PATTERNS.size():
			var match = Token.PATTERNS[i].search(raw_data, cursor)
			if not match:
				continue
			if match.get_start() != cursor:
				continue

			match_found = true
			match i:
				Token.WHITESPACE, Token.COMMENT:
					pass
				_:
					cursor = match.get_start()
					var token = Token.new(i, line, col, cursor, match.get_string())
					match i:
						Token.VALUE_STRING:
							token.value = Token.RX_STRING_TRIM.search(token.value).get_string()
					result.append(token)
			cursor = match.get_end()
			break

		if not match_found:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [line, col, raw_data[cursor]])
			break

	return result

func statementize(tokens: Array[Token]) -> Array[Statement]:
	var result : Array[Statement]

	var statement : Statement = null
	var depth : int = 0
	for i in tokens:
		if i.type == Token.TERMINATOR:
			if statement:
				if not statement.tokens.is_empty():
					result.append(statement)
				statement = null

				if i.value == '\n':
					depth = 0
				elif i.value == ':':
					depth += 1
		else:
			if not statement:
				if i.type == Token.INDENTATION:
					depth = i.value.length()
				statement = Statement.new(i.line, depth)
			if not i.type == Token.INDENTATION:
				statement.add_token(i)

	if statement:
		result.append(statement)
		statement.validate()

	return result

func validate_statements(statements: Array[Statement]) -> bool:
	var result := true
	for i in statements:
		if not i.validate():
			result = false
	return result

func export_statements(statements: Array[Statement]) -> void:
	Penny.import_statements(file.get_path(), statements)
