
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
# var stmts : Array[Stmt]

static func from_file(_file: FileAccess) -> PennyParser:
	return PennyParser.new(_file.get_as_text(true), _file)

func _init(_raw: String, _file: FileAccess = null) -> void:
	raw = _raw
	file = _file

func parse_tokens() -> Array[Token]:
	tokenize()
	# for i in tokens:
	# 	print(i)
	return tokens

func parse_statements() -> void:
	parse_tokens()
	statementize()
	# for i in stmts:
	# 	print(i)

func parse_file() -> void:
	print("***			Parsing file \"" + file.get_path() + "\"...")
	PennyException.active_file_path = file.get_path()

	parse_statements()

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
	var stmts : Array[Stmt] = []

	var stmt : Stmt = null
	var depth : int = 0
	for i in tokens.size():
		var token = tokens[i]
		if token.type == Token.TERMINATOR:
			if stmt:
				if not stmt.tokens.is_empty():
					stmts.push_back(stmt)
				stmt = null

				if token.value == '\n':
					depth = 0
				elif token.value == ':':
					depth += 1
		else:
			if not stmt:
				if token.type == Token.INDENTATION:
					depth = token.value.length()
				stmt = Stmt.new(Address.new(file.get_path(), stmts.size()), token_lines[i], depth, [])
			if not token.type == Token.INDENTATION:
				stmt.tokens.push_back(token)
	if stmt:
		stmts.push_back(stmt)

	Penny.stmt_dict[file.get_path()] = []
	for i in stmts:
		Penny.stmt_dict[file.get_path()].push_back(i.recycle())
	for i in Penny.stmt_dict[file.get_path()]:
		var exception : PennyException = i._validate()
		if exception:
			exception.push()
			Penny.valid = false
