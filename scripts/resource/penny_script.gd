
@tool
class_name PennyScript extends Resource

static var LINE_FEED_REGEX := RegEx.create_from_string("\\n")

@export_storage var id : int
@export_storage var stmts : Array[Stmt] = []

var diff : Array[Dictionary]
var diff_remap : Array[int]

func _init() -> void:
	pass


func update_from_file(file: FileAccess) -> void:
	var tokens := parse_tokens_from_raw(file.get_as_text(true), file)

	var old_stmts : Array[Stmt]
	if not Engine.is_editor_hint():
		old_stmts = stmts.duplicate()

	parse_and_register_stmts(tokens, file)

	if not Engine.is_editor_hint():
		diff = create_diff(old_stmts, stmts)
		diff_remap = create_diff_remap(old_stmts, stmts, diff)
		print(diff_remap)

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


func get_diff_remapped_stmt(old_stmt: Stmt) -> Stmt:
	return stmts[diff_remap[old_stmt.index_in_script]]


static func create_diff_remap(olds: Array[Stmt], news: Array[Stmt], _diff: Array[Dictionary]) -> Array[int]:

	var remap_table : Array[int] = []
	remap_table.resize(olds.size())

	print(Utils.array_to_string(_diff))

	var i := 0
	var j := 0
	for change in _diff:
		match change["type"]:
			"equal":
				remap_table[i] = j
				j += 1
			"delete":
				remap_table[i] = remap_table[i - 1]
				# j -= 1
				pass
			"insert":
				i -= 1
				j += 1
		i += 1


	# var i_new := 0

	# for i in _diff.size():
	# 	var change := _diff[i]
	# 	match change["type"]:
	# 		"equal":
	# 			remap_table[i] = i_new
	# 			i_new += 1
	# 		"delete":
	# 			remap_table[i] = -1
	# 		"insert":
	# 			i_new += 1

	return remap_table


static func create_diff(old: Array[Stmt], new: Array[Stmt]) -> Array[Dictionary]:

	var old_size := old.size()
	var new_size := new.size()

	var lcs_table = []
	lcs_table.resize(old_size + 1)
	for i in old_size + 1:
		var row = []
		row.resize(new_size + 1)
		row.fill(0)
		lcs_table[i] = row

	for i in old_size:
		for j in new_size:
			if old[i].hash_id == new[j].hash_id:
				lcs_table[i + 1][j + 1] = lcs_table[i][j] + 1
			else:
				lcs_table[i + 1][j + 1] = max(lcs_table[i + 1][j], lcs_table[i][j + 1])

	var result : Array[Dictionary] = []
	var i = old_size
	var j = new_size

	while i > 0 or j > 0:
		if i > 0 and j > 0 and old[i - 1].hash_id == new[j - 1].hash_id:
			result.push_front({"type": "equal", "value": old[i - 1]})
			i -= 1
			j -= 1
		elif j > 0 and (i == 0 or lcs_table[i][j-1] >= lcs_table[i - 1][j]):
			result.push_front({"type": "insert", "value": new[j - 1]})
			j -= 1
		else:
			result.push_front({"type": "delete", "value": old[i - 1]})
			i -= 1

	return result



func parse_and_register_stmts(tokens: Array[Token], context_file: FileAccess) -> void:
	stmts.clear()
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
				stmt = Stmt.new()
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
