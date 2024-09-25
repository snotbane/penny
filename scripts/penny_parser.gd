
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
