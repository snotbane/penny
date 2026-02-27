
@tool class_name PennyScript extends Resource

enum {
	INDENT_UNDEFINED,
	INDENT_TABS,
	INDENT_SPACES
}

const REGEX_MESSAGE_PATTERN := r"(?s)[>+](?!=)[\t ]*.*?(?=\n+[\t ]{,%d}(?![\t ])(?:\S|$))"

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
		return self.news[self.map[cursor.index]]

class Token extends RefCounted:
	enum Type {
		INDENTATION,
		VALUE_MESSAGE,
		VALUE_STRING,
		KEYWORD,
		VALUE_BOOLEAN,
		VALUE_COLOR,
		ASSIGNMENT,
		OPERATOR,
		COMMENT,
		IDENTIFIER,
		VALUE_NUMBER,
		TERMINATOR,
		WHITESPACE,
	}
	static var TYPE_PATTERNS : Dictionary[Type, RegEx] = {
		Type.INDENTATION:			RegEx.create_from_string(r"(?m)^[\t ]+"),
		Type.VALUE_MESSAGE:			RegEx.new(),
		Type.VALUE_STRING:			RegEx.create_from_string(r"(?s)(?<!\\)(['\"`]{3}|['\"`])(.*?)(?<!\\)\1"),
		Type.KEYWORD:				RegEx.create_from_string(r"\b(?:await|call|else|elif|if|init|jump|label|let|match|menu|pass|print|return|var)\b"),
		Type.VALUE_BOOLEAN:			RegEx.create_from_string(r"\b(?:[Tt]rue|TRUE|[Ff]alse|FALSE)\b"),
		Type.VALUE_COLOR:			RegEx.create_from_string(r"(?i)#(?:[0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{3,4})(?![0-9a-f])"),
		Type.ASSIGNMENT:			RegEx.create_from_string(r"===|([+\-*/]?)=(?!=)"),
		Type.OPERATOR:				Op.PATTERN_COMPILED,
		Type.COMMENT:				RegEx.create_from_string(r"(?ms)(([#/])\*.*?(\*\2))|((#|\/{2}).*?$)"),
		Type.IDENTIFIER:			RegEx.create_from_string(r"~|(?:[a-zA-Z_]\w*)"),
		Type.VALUE_NUMBER:			RegEx.create_from_string(r"\d+\.\d*|\.?\d+"),
		Type.TERMINATOR:			RegEx.create_from_string(r"(?m)(?<!\[)[:;\n]+(?!\])"),
		Type.WHITESPACE:			RegEx.create_from_string(r"(?m)[ \n]+|(?<!^|\t)\t+"),
	}

	enum Literal {
		MESSAGE,
		STRING,
		COLOR,
		NULL,
		BOOLEAN_TRUE,
		BOOLEAN_FALSE,
		NUMBER_DECIMAL,
		NUMBER_INTEGER,
	}

	static var LITERAL_PATTERNS : Dictionary[Literal, RegEx] = {
		Literal.MESSAGE:			RegEx.create_from_string(r"^[>+]"),
		Literal.STRING: 			TYPE_PATTERNS[Token.Type.VALUE_STRING],
		Literal.COLOR: 				TYPE_PATTERNS[Token.Type.VALUE_COLOR],
		Literal.NULL: 				RegEx.create_from_string(r"\b(?:[Nn]ull|NULL)\b"),
		Literal.BOOLEAN_TRUE: 		RegEx.create_from_string(r"\b(?:[Tt]rue|TRUE)\b"),
		Literal.BOOLEAN_FALSE: 		RegEx.create_from_string(r"\b(?:[Ff]alse|FALSE)\b"),
		Literal.NUMBER_DECIMAL: 	RegEx.create_from_string(r"\b(?:\d+\.\d+|\d+\.|\.\d+)\b"),
		Literal.NUMBER_INTEGER: 	RegEx.create_from_string(r"\b\d+\b"),
	}

	static func parse_code_as_literal(raw: String) -> Variant:
		for i in LITERAL_PATTERNS.size():
			var rx : RegExMatch = LITERAL_PATTERNS[i].search(raw)
			if rx: match i:
				Literal.MESSAGE:		return DialogMessage.new(raw)
				Literal.STRING:			return rx.get_string(2)
				Literal.COLOR:			return Color(raw)
				Literal.NULL:			return null
				Literal.BOOLEAN_TRUE:	return true
				Literal.BOOLEAN_FALSE:	return false
				Literal.NUMBER_DECIMAL:	return float(raw)
				Literal.NUMBER_INTEGER:	return int(raw)
		return StringName(raw)

	var type : Type
	var value : Variant


	func _init(_type: Type, _raw: String) -> void:
		type = _type

		match type:
			Token.Type.INDENTATION:
				value = _raw.length()
			Token.Type.OPERATOR:
				value = Op.new_from_string(_raw)
			_:
				value = Token.parse_code_as_literal(_raw)


	func _to_string() -> String:
		var token_type_string : String
		match type:
			Token.Type.INDENTATION: token_type_string = "IDT"
			Token.Type.VALUE_MESSAGE: token_type_string = "MSG"
			Token.Type.VALUE_STRING: token_type_string = "STR"
			Token.Type.KEYWORD: token_type_string = "KEY"
			Token.Type.VALUE_BOOLEAN: token_type_string = "BOO"
			Token.Type.VALUE_COLOR: token_type_string = "COL"
			Token.Type.VALUE_NUMBER: token_type_string = "NUM"
			Token.Type.OPERATOR: token_type_string = "OPR"
			Token.Type.COMMENT: token_type_string = "COM"
			Token.Type.ASSIGNMENT: token_type_string = "ASG"
			Token.Type.IDENTIFIER: token_type_string = "IDR"
			Token.Type.TERMINATOR: token_type_string = "TRM"
			Token.Type.WHITESPACE: token_type_string = "WHT"
			_: token_type_string = "INV"
		return "%s:%s" % [token_type_string, str(value)]

static var LINE_FEED_REGEX : RegEx

static func _static_init() -> void:
	LINE_FEED_REGEX = RegEx.create_from_string(r"\n")

@export_storage var id : int
@export_storage var stmts : Array[Stmt] = []
@export_storage var errors : Array[String] = []

var diff : Diff

func _init(path : String) -> void:
	id = hash(path)


func update_from_file(file: FileAccess) -> void:
	errors.clear()

	# var tokens := parse_code_to_tokens(file.get_as_text(), file)
	# print(tokens)

	var old_stmts : Array[Stmt]
	if not Engine.is_editor_hint():
		old_stmts = stmts.duplicate()

	stmts = parse_code_to_stmts(file.get_as_text(), file)

	# parse_tokens_to_stmts(tokens, file)
	# # print_stmts(stmts)
	# # print(get_metrics(file.get_path()))

	if not Engine.is_editor_hint():
		diff = Diff.new(old_stmts, stmts)
		# if diff.changes: print(diff)


func get_metrics(known_path: String = "") -> Dictionary:
	var total_word_count := 0
	var total_letter_count := 0
	var total_dialogs := 0
	for stmt in stmts:
		if stmt is not StmtDialog: continue
		var metrics : Dictionary = stmt.get_metrics()
		total_word_count += metrics[&"word_count"]
		total_letter_count += metrics[&"letter_count"]
		total_dialogs += 1

	return {
		&"path": known_path,
		&"dialogs": total_dialogs,
		&"words": total_word_count,
		&"chars": total_letter_count,
		&"chars_per_word": float(total_letter_count) / float(total_word_count)
	}


static func print_stmts(arr: Array[Stmt]) -> void:
	for i in arr: print("%s (%s)" % [i, i.get_script().get_global_name()])


func parse_code_to_stmts(raw: String, context_file: FileAccess = null) -> Array[Stmt]:
	#region Raw to Tokens

	var indent_type := INDENT_UNDEFINED
	Token.TYPE_PATTERNS[Token.Type.VALUE_MESSAGE].compile(REGEX_MESSAGE_PATTERN % [ 0 ])

	var tokens : Array[Token] = []

	var cursor := 0
	while cursor < raw.length():
		var any_token_found := false
		var error := String()

		# var indent_expected : String =

		for k in Token.TYPE_PATTERNS.keys():
			var m_token : RegExMatch = Token.TYPE_PATTERNS[k].search(raw, cursor)
			if m_token == null or m_token.get_start() != cursor: continue
			any_token_found = true
			var token_string := m_token.get_string()

			match k:
				Token.Type.INDENTATION:
					if ' ' in token_string and '\t' in token_string:
						error = "Illegal indentation: contains a mixture of tabs and spaces."
						break

					match indent_type:
						INDENT_SPACES:
							if '\t' in token_string:
								error = "Illegal indentation: document must use the same kind of indentation throughout (spaces)."
								break

						INDENT_TABS:
							if ' ' in token_string:
								error = "Illegal indentation: document must use the same kind of indentation throughout (tabs)."
								break

						INDENT_UNDEFINED:
							match token_string[0]:
								' ':	indent_type = INDENT_SPACES
								'\t':	indent_type = INDENT_TABS

					tokens.push_back(Token.new(k, token_string))
					Token.TYPE_PATTERNS[Token.Type.VALUE_MESSAGE].compile(REGEX_MESSAGE_PATTERN % [ tokens.back().value ])

				Token.Type.WHITESPACE, Token.Type.COMMENT:
					pass

				_:
					if not tokens.is_empty() and k == Token.Type.TERMINATOR and tokens.back().type == Token.Type.TERMINATOR:
						tokens.back().value += token_string

					else:
						tokens.push_back(Token.new(k, token_string))

			cursor = m_token.get_end() if m_token.get_end() != cursor else cursor + 1
			break

		if not any_token_found:
			error = "Unrecognized token '%s'." % [raw[cursor]]

		if error:
			var address_numbers := get_line_and_column_numbers(cursor, raw)
			printerr("%s(ln %s, cl %s): %s" % [
				(context_file.get_path() + " ") if context_file else "",
				address_numbers[0],
				address_numbers[1],
				error
			])
			break

	#endregion

	var token_groups : Array = [[]]
	var g := 0
	for token in tokens:
		if token.type == Token.Type.TERMINATOR:
			if not token_groups[g].is_empty():
				token_groups.push_back([])
				g += 1
			continue
		token_groups[g].push_back(token)
	if token_groups.back().is_empty(): token_groups.pop_back()

	var result : Array[Stmt] = []
	result.resize(token_groups.size())
	var offset := 0
	var error_count := 0
	for i in token_groups.size():
		var j := i - offset
		var stmt_temp := Stmt.new()
		stmt_temp.populate(self, j, token_groups[i])
		result[j] = recycle_stmt(stmt_temp, j, token_groups[i], context_file)
		if result[j]:
			result[j].populate_from_other(stmt_temp, token_groups[i])
		else:
			offset += 1
			error_count += 1
	result.resize(result.size() - error_count)

	return result


static func recycle_stmt(stmt: Stmt, index: int, tokens: Array, context_file: FileAccess = null) -> Stmt:
	if tokens[0].type == Token.Type.INDENTATION:
		tokens.pop_front()
		if tokens.size() == 0: return null

	if tokens.size() == 1 and tokens[0].type == Token.Type.OPERATOR and tokens[0].value.type == Op.MORE_THAN:
		tokens.pop_front()
		return StmtDialogClose.new()

	var front_keywords : Array[Token] = []
	while tokens and tokens.front().type == Token.Type.KEYWORD:
		front_keywords.push_back(tokens.pop_front())

	for token in tokens: if token.type == Token.Type.ASSIGNMENT: return StmtAssign.new(StmtCell.get_storage_qualifier_from_front_tokens(front_keywords))

	if front_keywords:
		match front_keywords[0].value:
			&"call": 	return StmtJumpCall.new()
			&"else": 	return StmtConditionalElse.new()
			&"elif": 	return StmtConditionalElif.new()
			&"if": 		return StmtConditionalIf.new()
			&"init":	return StmtInit.new()
			&"jump": 	return StmtJump.new()
			&"label": 	return StmtLabel.new()
			&"match": 	return StmtMatch.new()
			&"menu": 	return StmtMenu.new()
			&"pass": 	return StmtPass.new()
			&"print": 	return StmtPrint.new()
			&"return":	return StmtReturn.new()

	var block_header := stmt.get_prev_in_lower_depth()
	if block_header:
		if block_header is StmtMatch:
			return StmtConditionalMatch.new()
		elif block_header is StmtMenu:
			return StmtConditionalMenu.new()

	match tokens.back().type:
		Token.Type.VALUE_STRING:
			return StmtDialog.new()
		Token.Type.OPERATOR:
			if tokens.back().value.type == Op.GROUP_CLOSE:
				return StmtFunc.new(front_keywords and front_keywords[0].value == &"await")

	if front_keywords:
		match front_keywords[0].value:
			&"await":	return StmtAwait.new()

	match tokens.front().type:
		Token.Type.IDENTIFIER:
			return StmtCell.new(StmtCell.get_storage_qualifier_from_front_tokens(front_keywords))
		Token.Type.OPERATOR:
			if tokens.front().value.type == Op.DOT and tokens[1].type == Token.Type.IDENTIFIER:
				return StmtCell.new(StmtCell.get_storage_qualifier_from_front_tokens(front_keywords))

	assert(false, "No Stmt recycled from tokens: %s" % str(tokens))
	return null


static func get_line_and_column_numbers(char_index: int, raw: String) -> Array[int]:
	var matches := LINE_FEED_REGEX.search_all(raw, 0, char_index)
	var row := matches.size()
	var col : int
	if row == 0:
		col = char_index
	else:
		col = char_index - matches[row - 1].get_end()
	return [row + 1, col + 1]
