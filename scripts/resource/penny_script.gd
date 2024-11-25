
@tool
class_name PennyScript extends Resource

class Diff:
	class Entry:
		enum {
			EQUAL,
			INSERT,
			DELETE
		}
		var type : int
		var value : Stmt

		func _init(_type: int, _value: Stmt) -> void:
			self.type = _type
			self.value = _value

		func _to_string() -> String:
			var result : String
			match self.type:
				EQUAL: result = "  "
				INSERT: result = "+ "
				DELETE: result = "- "
			result += self.value.to_string()
			return result

	var olds : Array[Stmt]
	var news : Array[Stmt]
	var changes : Array[Entry]
	var map : Array[int]

	func _init(_old: Array[Stmt], _new: Array[Stmt]) -> void:
		self.olds = _old.duplicate()
		self.news = _new.duplicate()
		var lcs_table = []
		lcs_table.resize(olds.size() + 1)
		for i in olds.size() + 1:
			var row : Array[int] = []
			row.resize(news.size() + 1)
			row.fill(0)
			lcs_table[i] = row

		for i in olds.size():
			for j in news.size():
				if olds[i].hash_id == news[j].hash_id:
					lcs_table[i + 1][j + 1] = lcs_table[i][j] + 1
				else:
					lcs_table[i + 1][j + 1] = max(lcs_table[i + 1][j], lcs_table[i][j + 1])

		changes = []
		var i := olds.size()
		var j := news.size()
		while i > 0 or j > 0:
			if i > 0 and j > 0 and olds[i - 1].hash_id == news[j - 1].hash_id:
				changes.push_front(Entry.new(Entry.EQUAL, olds[i - 1]))
				i -= 1
				j -= 1
			elif j > 0 and (i == 0 or lcs_table[i][j-1] >= lcs_table[i - 1][j]):
				changes.push_front(Entry.new(Entry.INSERT, news[j - 1]))
				j -= 1
			else:
				changes.push_front(Entry.new(Entry.DELETE, olds[i - 1]))
				i -= 1

		map = []
		map.resize(olds.size())
		i = 0
		j = 0
		for change in changes:
			match change.type:
				Entry.EQUAL:
					map[i] = j
					j += 1
				Entry.INSERT:
					i -= 1
					j += 1
				Entry.DELETE:
					# # Use this to explicitly state that the entry is no longer available, defer logic elsewhere
					# map[i] = -1
					# Use this to bake remap logic in here. Every old statement is guaranteed to have a new remap.
					map[i] = map[i - 1]
			i += 1


	func _to_string() -> String:
		var inserts := 0
		var deletes := 0
		for change in changes:
			match change.type:
				Entry.INSERT: inserts += 1
				Entry.DELETE: deletes += 1
		if inserts == 0 and deletes == 0:
			return "Diff: no changes."
		return "Diff: + %s insertions, - %s deletions." % [inserts, deletes]


	# func get_recent_remap(records: Array[Record]) -> Stmt:
	# 	for i in records.size():
	# 		var cursor : Stmt = records[records.size() - (i + 1)].stmt
	# 		var index := cursor..map[cursor.index_in_script]
	# 		if index == -1: continue
	# 		return self.new[index]
	# 	return self.new[0]


	func remap_stmt_index(cursor: Stmt) -> Stmt:
		return self.news[self.map[cursor.index_in_script]]


static var LINE_FEED_REGEX := RegEx.create_from_string("\\n")

@export_storage var id : int
@export_storage var stmts : Array[Stmt] = []

var diff : Diff

func _init() -> void:
	pass


func update_from_file(file: FileAccess) -> void:
	var tokens := parse_tokens_from_raw(file.get_as_text(true), file)

	var old_stmts : Array[Stmt]
	if not Engine.is_editor_hint():
		old_stmts = stmts.duplicate()

	self.parse_and_register_stmts(tokens, file)

	if not Engine.is_editor_hint():
		diff = Diff.new(old_stmts, stmts)
		print(diff)

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
