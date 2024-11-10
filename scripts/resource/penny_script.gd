
@tool
class_name PennyScript extends Resource

static var LINE_FEED_REGEX := RegEx.create_from_string("\\n")

@export_storage var id : int
@export_storage var stmts : Array[Stmt_]

func _init() -> void:
	pass


func update_from_file(file: FileAccess) -> void:
	var tokens := parse_tokens_from_raw(file.get_as_text(true), file)
	parse_and_register_stmts(tokens, file)

	for stmt in stmts:
		var exception := stmt.validate_self()
		if exception:
			exception.push()
		else:
			stmt.validate_self_post_setup()
	for stmt in stmts:
		var exception := stmt.validate_cross()
		if exception:
			exception.push()


func parse_and_register_stmts(tokens: Array[Token], context_file: FileAccess) -> void:
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
				stmt = Stmt_.new()
				stmt.populate(self, stmts.size(), 0, depth, [])
			if not token.type == Token.INDENTATION:
				stmt.tokens.push_back(token)
	if stmt:
		stmts.push_back(stmt)

	for i in stmts.size():
		var i_stmt := stmts[i]
		var recycle = i_stmt.recycle()
		recycle.file_address = FileAddress.new(context_file.get_path(), i_stmt.index_in_file)
		stmts[i] = recycle


static func parse_tokens_from_raw(raw: String, context_file: FileAccess = null) -> Array[Token]:
	var result : Array[Token] = []

	## If this gets stuck in a loop, Token.PATTERNS has a regex pattern that matches with something of 0 length, e.g. ".*"
	var cursor := 0
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
					result.push_back(token)
			cursor = match.get_end()
			break

		if not match_found:
			var address_numbers := get_line_and_column_numbers(cursor, raw)
			var exception : PennyException
			if context_file:
				exception = PennyExceptionRef.new(FileAddress.new(context_file.get_path(), address_numbers[0], address_numbers[1]), "Unrecognized token '%s'." % raw[cursor])
			else:
				exception = PennyException.new("Unrecognized token '%s' at (ln %s, cl %s)." % [raw[cursor], address_numbers[0], address_numbers[1]])
			exception.push()
			break
	return result


static func get_line_and_column_numbers(char_index: int, raw: String) -> Array[int]:
	var matches := LINE_FEED_REGEX.search_all(raw, 0, char_index)
	var row := matches.size()
	var col : int
	if row == 0:
		col = char_index
	else:
		col = char_index - matches[row - 1].get_end()
	return [row + 1, col + 1]
