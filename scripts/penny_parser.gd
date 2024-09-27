
## Responsible for translating and validating a single file into workable statements.
class_name PennyParser extends Object

const RX_LF = "\\n"

static var rx_line_col := RegEx.create_from_string(RX_LF)
var _cursor : int = 0
var cursor : int :
	get : return _cursor
	set (value) :
		_cursor = value

		var rm_lf := rx_line_col.search_all(raw, 0, _cursor)

		line = rm_lf.size() + 1

		col = _cursor + 1
		if line != 1:
			col -= rm_lf[line - 2].get_end()

static var line : int = 0
static var col : int = 0

var file : FileAccess
var raw : String
var tokens : Array[Token]
var token_lines : Array[int]
var statements : Array[Statement]

static func from_file(_file: FileAccess) -> PennyParser:
	return PennyParser.new(_file.get_as_text(true), _file)

func _init(_raw: String, _file: FileAccess = null) -> void:
	raw = _raw
	file = _file

func parse_tokens() -> Array[Token]:
	tokenize()
	for i in tokens:
		print(i)
	return tokens

func parse_statements() -> Array[Statement]:
	parse_tokens()
	statementize()
	# for i in statements:
	# 	print(i)
	return statements

func parse_file() -> void:
	print("***			Parsing file \"" + file.get_path() + "\"...")
	PennyException.active_file_path = file.get_path()

	parse_statements()

	if validate_statements():
		for i in statements:
			print(i)
		export_statements()
	else:
		Penny.valid = false

	PennyException.active_file_path = PennyException.UNKNOWN_FILE
	print("***			Finished parsing file \"" + file.get_path() + "\".")

func tokenize() -> void:
	tokens.clear()

	## If this gets stuck in a loop, Token.PATTERNS has a regex pattern that matches with something of 0 length, e.g. ".*"
	cursor = 0
	while cursor < raw.length():
		var match_found = false

		for i in Token.PATTERNS.size():
			var match = Token.PATTERNS[i].search(raw, cursor)
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
					var token = Token.new(i, match.get_string())
					tokens.push_back(token)
					token_lines.push_back(line)
			cursor = match.get_end()
			break

		if not match_found:
			PennyException.new("Unrecognized token at ln %s cl %s" % [line, col]).push()
			break

# Separates statements based on terminators and indentation; For type assignment, etc. see Statement validations.
func statementize() -> void:
	statements.clear()

	var statement : Statement = null
	var depth : int = 0
	for i in tokens.size():
		var token = tokens[i]
		if token.type == Token.TERMINATOR:
			if statement:
				if not statement.tokens.is_empty():
					statements.append(statement)
				statement = null

				if token.value == '\n':
					depth = 0
				elif token.value == ':':
					depth += 1
		else:
			if not statement:
				if token.type == Token.INDENTATION:
					depth = token.value.length()
				statement = Statement.new(token_lines[i], depth, Address.new(file.get_path(), statements.size()))
			if not token.type == Token.INDENTATION:
				statement.tokens.push_back(token)

	if statement:
		statements.append(statement)

func validate_statements() -> bool:
	var result := true
	var exceptions : Array[PennyException] = []
	for i in statements:
		var e = i.validate()
		if e:
			exceptions.push_back(e)
	result = exceptions.is_empty()
	for i in exceptions:
		printerr(i)
	return result

func export_statements() -> void:
	Penny.import_statements(file.get_path(), statements)
