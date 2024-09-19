
## Environment for all Penny runtime data. This is a singleton and all data is static as it comes from the penny scripts and save files.
class_name Penny extends Object

## Single token in script representing a clause or value.
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
	var value : String

	var col_end : int :
		get: return col + value.length()

	var belongs_in_expression_variant : bool :
		get: return type >= VALUE_STRING && type <= OPERATOR_NUMERIC_EQUALITY

	var belongs_in_expression_boolean : bool :
		get: return type == PARENTHESIS_CAPS || ( type >= VALUE_BOOLEAN && type <= OPERATOR_BOOLEAN )

	func _init(_type: int, _line: int, _col: int, _value: String) -> void:
		type = _type
		line = _line
		col = _col
		value = _value

	func equals(other: Token) -> bool:
		return value == other.value

	func _to_string() -> String:
		return "ln %s cl %s type %s : %s" % [line, col, type, value]

## Single statement separated by newline or semicolon.
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
	var address : Address
	var line : int
	var depth : int
	var tokens : Array[Token]

	var is_halting : bool :
		get:
			match type:
				MESSAGE, MENU: return true
			return false

	var is_record_user_facing : bool :
		get: return is_halting

	func _init(_line: int, _depth: int, _address: Address) -> void:
		line = _line
		depth = _depth
		address = _address

	func hash() -> int:
		return address.hash()

	func equals(other: Statement) -> bool:
		return self.hash() == other.hash()

	func debug_string() -> String:
		return "ln %s dp %s type %s : %s" % [line, depth, type, to_string()]

	func _to_string() -> String:
		var result := ""
		for i in tokens:
			result += i.value + " "
		return result.substr(0, result.length() - 1)

	func get_prev(offset: int = 1) -> Statement :
		if address.index - offset < 0: return null
		return Penny.statements[address.path][address.index - offset]

	func get_next(offset: int = 1) -> Statement :
		if address.index + offset >= Penny.statements.size(): return null
		return Penny.statements[address.path][address.index + offset]

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

## Record of a statement that occurred, used for historical purposes.
class Record:

	var statement : Statement
	var text : String

	var verbosity : int :
		get:
			match statement.type:

				## Player Essentials
				Statement.MESSAGE, Statement.MENU: return 0

				## Debug Essentials
				Statement.ASSIGN, Statement.PRINT: return 1

				## Debug Helpers
				Statement.JUMP, Statement.RISE, Statement.DIVE, Statement.CONDITION: return 2

			return -1

	func _init(__statement: Statement, __text) -> void:
		statement = __statement
		text = __text

## Location of a Statement specified by a file path and array index.
class Address:
	var path : String

	var _index : int
	var index : int :
		get: return _index
		set (value):
			_index = max(value, 0)

	func _init(__path: String, __index: int) -> void:
		path = __path
		index = __index

	func hash() -> int:
		return path.hash() + hash(index)

	func equals(other: Address) -> bool:
		return self.hash() == other.hash()

	func _to_string() -> String:
		return "%s:%s" % [path, index]

## Displayable text capable of producing decorations.
class Message:
	static var RX_DEPTH_REMOVAL_PATTERN = "(?<=\\n)\\t{0,%s}"

	var text: String

	func _init(from: Statement) -> void:
		match from.type:
			Statement.MESSAGE:
				var raw = from.tokens[0].value

				var rx_whitespace = RegEx.create_from_string(RX_DEPTH_REMOVAL_PATTERN % from.depth)

				text = rx_whitespace.sub(raw, "", true)
			Statement.PRINT:
				text = from.tokens[0].value

	func hash() -> int:
		return text.hash()

static var statements : Dictionary		## String : Statement
static var labels : Dictionary			## StringName : Address
static var valid : bool = true

static var viewed_message_hashes : Array[int]

static func clear() -> void:
	valid = true
	statements.clear()
	labels.clear()

static func import_statements(path: String, _statements: Array[Statement]) -> void:
	statements[path] = _statements

	## Assign labels
	var i := -1
	for stmt in _statements:
		i += 1
		if stmt.type == Statement.LABEL:
			if labels.has(stmt.tokens[1].value):
				printerr("Label %s already exists (this check should be moved to the parser validations)" % stmt.tokens[1])
			labels[stmt.tokens[1].value] = Address.new(path, i)

static func get_address_from_label(label: StringName) -> Address:
	if labels.has(label):
		return labels[label]
	else:
		printerr("Label '%s' does not exist in the current Penny environment." % label)
		return null

static func get_statement_from(address: Address) -> Statement:
	if address.index < statements[address.path].size():
		return statements[address.path][address.index]
	return null

# static func get_roll_back_address_from(address: Address) -> Statement:
