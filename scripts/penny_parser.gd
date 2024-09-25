
## Responsible for translating and validating a single file into workable statements.
class_name PennyParser extends Object

const RX_LF = "\\n"

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
	# print("***				TOKENS:")
	var tokens := tokenize()
	# for i in tokens:
	# 	print(i)

	## Statement Creation
	# print("***				STATEMENTS:")
	var statements := statementize(tokens)
	# for i in statements:
	# 	print(i.debug_string())

	## Statement Validations
	# print("***				VALIDATIONS:")
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
					var token = Token.new(i, line, col, match.get_string())
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

# Separates statements based on terminators and indentation; For type assignment, etc. see Statement validations.
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
				statement = Statement.new(i.line, depth, Address.new(file.get_path(), result.size()))
			if not i.type == Token.INDENTATION:
				statement.tokens.push_back(i)

	if statement:
		result.append(statement)

	return result

func validate_statements(statements: Array[Statement]) -> bool:
	var result := true
	for i in statements:
		if not validate(i):
			result = false
	return result

func export_statements(statements: Array[Statement]) -> void:
	Penny.import_statements(file.get_path(), statements)


## VALIDATIONS

static func validate(stmt: Statement) -> bool:
	if stmt.tokens.size() == 0:
		PennyException.push_error(PennyException.PARSE_ERROR_UNCAUGHT_VALIDATION, [stmt])
		return false

	match stmt.tokens[0].type:
		Token.VALUE_STRING:
			if stmt.tokens.size() == 1:
				return validate_message_extension(stmt, Statement.MESSAGE)
			elif stmt.tokens.size() == 2:
				return validate_message_direct(stmt, Statement.MESSAGE)
		Token.KEYWORD:
			match stmt.tokens[0].value:
				'init': return validate_keyword_standalone(stmt, Statement.INIT)
				'pass': return validate_keyword_standalone(stmt, Statement.PASS)
				'rise': return validate_keyword_standalone(stmt, Statement.RISE)
				'print': return validate_keyword_with_optional_expression(stmt, Statement.PRINT)
				'return': return validate_keyword_with_optional_expression(stmt, Statement.RETURN)
				'dive': return validate_keyword_with_required_identifier(stmt, Statement.DIVE)
				'label': return validate_keyword_with_required_identifier(stmt, Statement.LABEL)
				'jump': return validate_keyword_with_required_identifier(stmt, Statement.JUMP)
				'elif', 'else', 'if': return validate_conditional(stmt, Statement.CONDITION)
				'object': return validate_keyword_standalone_with_required_block(stmt, Statement.OBJECT_MANIPULATE)
				'filter': return validate_keyword_standalone_with_required_block(stmt, Statement.FILTER)
		Token.IDENTIFIER:
			if stmt.tokens.size() == 1:
				return validate_object_manipulation(stmt, Statement.OBJECT_MANIPULATE)
			match stmt.tokens[1].type:
				Token.VALUE_STRING:
					return validate_message_direct(stmt, Statement.MESSAGE)
				Token.ASSIGNMENT:
					return validate_object_assignment(stmt, Statement.ASSIGN)

	PennyException.push_error(PennyException.PARSE_ERROR_UNCAUGHT_VALIDATION, [stmt])
	return false

static func validate_keyword_standalone(stmt: Statement, expect: int) -> bool:
	stmt.type = expect
	if stmt.tokens.size() == 1:
		stmt.tokens = []
		return true
	else:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [stmt.tokens[1]])
		return false

static func validate_keyword_with_optional_expression(stmt: Statement, expect: int) -> bool:
	stmt.type = expect
	stmt.tokens.pop_front()
	if stmt.tokens.size() == 0:
		return true
	return validate_expression(stmt, stmt.tokens)

static func validate_keyword_with_required_expression(stmt: Statement, expect: int) -> bool:
	stmt.type = expect
	if stmt.tokens.size() == 1:
		PennyException.push_error(PennyException.PARSE_ERROR_EXPECTED_EXPRESSION, [line, stmt.tokens[0].col_end, stmt.tokens[0].value])
		return false
	stmt.tokens.pop_front()
	return validate_expression(stmt, stmt.tokens)

static func validate_keyword_with_required_identifier(stmt: Statement, expect: int) -> bool:
	stmt.type = expect
	if stmt.tokens.size() == 1:
		PennyException.push_error(PennyException.PARSE_ERROR_EXPECTED_IDENTIFIER, [line, stmt.tokens[0].col_end, stmt.tokens[0].value])
		return false
	stmt.tokens.pop_front()
	if stmt.tokens.size() > 1:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [stmt.tokens[1]])
		return false
	if stmt.tokens[0].type != Token.IDENTIFIER:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [stmt.tokens[0]])
		return false
	return true

static func validate_keyword_standalone_with_required_block(stmt: Statement, expect: int) -> bool:
	return validate_keyword_standalone(stmt, expect)

static func validate_object_manipulation(stmt: Statement, expect: int) -> bool:
	stmt.type = expect
	return true

static func validate_object_assignment(stmt: Statement, expect: int) -> bool:
	stmt.type = expect
	if stmt.tokens[1].value == 'is':
		if stmt.tokens.size() > 3:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [stmt.tokens[3]])
			return false
		if stmt.tokens[2].type != Token.IDENTIFIER && stmt.tokens[2].value != 'object':
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [stmt.tokens[2]])
			return false
		return true
	else:
		var expr := stmt.tokens
		expr.pop_front()
		expr.pop_front()
		return validate_expression(stmt, expr)

static func validate_message_direct(stmt: Statement, expect: int) -> bool:
	stmt.type = expect
	if stmt.tokens.size() > 2:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [stmt.tokens[2]])
		return false
	if stmt.tokens[0].type != Token.IDENTIFIER && stmt.tokens[0].type != Token.VALUE_STRING:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [stmt.tokens[0]])
		return false
	if stmt.tokens[1].type != Token.VALUE_STRING:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [stmt.tokens[1]])
		return false
	return true

static func validate_message_extension(stmt: Statement, expect: int) -> bool:
	stmt.type = expect
	if stmt.tokens.size() != 1:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [stmt.tokens[1]])
		return false
	return true

static func validate_conditional(stmt: Statement, expect: int) -> bool:
	stmt.type = expect
	var expr := stmt.tokens
	expr.pop_front()
	return validate_expression(stmt, expr)


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




