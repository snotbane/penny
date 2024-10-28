
## Responsible for translating and validating a single file into workable statements.
class_name PennyParser extends RefCounted

const RX_LF := "\\n"

static var rx_line_col : RegEx
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
var stmts : Array[Stmt_]

static func from_file(_file: FileAccess) -> PennyParser:
	return PennyParser.new(_file.get_as_text(true), _file)

func _init(_raw: String, _file: FileAccess = null) -> void:
	rx_line_col = RegEx.create_from_string(RX_LF)
	raw = _raw
	file = _file

func parse_tokens() -> Array[PennyException]:
	var exceptions = tokenize()
	# for i in tokens:
	# 	print(i)
	return exceptions


func parse_statements() -> Array[PennyException]:
	var exceptions = tokenize()
	if exceptions.is_empty():
		exceptions = statementize()
	# Penny.log("================================================================")
	# for i in tokens:
	# 	Penny.log(i.to_string())
	# for i in stmts:
	# 	print(i)
	return exceptions

func parse_file() -> Array[PennyException]:
	# print("***			Parsing file \"" + file.get_path() + "\"...")
	PennyException.active_file_path = file.get_path()

	var result = parse_statements()

	PennyException.active_file_path = PennyException.UNKNOWN_FILE
	# print("***			Finished parsing file \"" + file.get_path() + "\".")

	return result

func tokenize() -> Array[PennyException]:
	var result : Array[PennyException] = []

	tokens.clear()

	## If this gets stuck in a loop, Token.PATTERNS has a regex pattern that matches with something of 0 length, e.g. ".*"
	cursor = 0
	while cursor < raw.length():
		var match_found = false

		var i := -1
		for k in Token.PATTERNS.keys():
			i += 1
			var match = Token.PATTERNS[k].search(raw, cursor)
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
			result.push_back(PennyExceptionRef.new(FileAddress.new(file.get_path(), line, col), "Unrecognized token '%s'." % raw[cursor]))
			# cursor += 1
			break

	return result

# Separates statements based on terminators and indentation; For type assignment, etc. see Statement validations.
func statementize() -> Array[PennyException]:
	stmts.clear()

	var stmt : Stmt_ = null
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
				stmt = Stmt_.new(Stmt_.Address.new(0, stmts.size()), token_lines[i], depth, [])
			if not token.type == Token.INDENTATION:
				stmt.tokens.push_back(token)
	if stmt:
		stmts.push_back(stmt)


	var result : Array[PennyException] = []
	for i in stmts.size():
		stmt = stmts[i]
		var recycle = stmt.recycle()
		recycle.file_address = FileAddress.new(file.get_path(), stmt.line)
		stmts[i] = recycle
	for i in stmts:
		var e := i.validate()
		if e:
			result.push_back(e)
		else:
			i.setup()

	return result
