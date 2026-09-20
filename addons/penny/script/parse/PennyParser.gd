@tool
extends RefCounted


static var LINE_FEED_REGEX: RegEx = RegEx.create_from_string(r"\n")

static func get_line_column_numbers(text: String, cursor: int) -> Array[int]:
	var matches := LINE_FEED_REGEX.search_all(text, 0, cursor)
	var row := matches.size()
	var col: int
	if row == 0:
		col = cursor
	else:
		col = cursor - matches[row - 1].get_end()
	return [row + 1, col + 1]

var file: FileAccess
var file_name: String
var previous: PennyScript
var result: PennyScript

var tokens: Array
var token_lines: Dictionary

var text: String
var line: int
var column: int
var cursor: int:
	set(value):
		cursor = value

		var address_numbers := get_line_column_numbers(text, cursor)
		line = address_numbers[0]
		column = address_numbers[1]


func _init(__file__: FileAccess = null, __previous__: PennyScript = null) -> void:
	file = __file__
	previous = __previous__


func process() -> PennyScript:
	if previous:
		previous._sunset()

	result = PennyScript.new()

	if not file:
		return

	result.safe_path = file.get_path()

	tokenize(file)
	statementize()

	return result


func tokenize(source) -> void:
	if source is String:
		text = source
		file_name = "<Unknown source>"
	elif source is FileAccess:
		text = source.get_as_text()
		file_name = source.get_path().get_file().get_basename()

	cursor = 0
	tokens = []
	token_lines = {}

	while cursor < text.length():
		var token_found := false

		for k in PennyScript.Token.TYPE_PATTERNS:
			var token_match: RegExMatch = PennyScript.Token.TYPE_PATTERNS[k].search(text, cursor)

			if token_match == null or token_match.get_start() != cursor: continue

			match k:
				PennyScript.Token.Type.WHITESPACE, PennyScript.Token.Type.COMMENT:
					pass
				_:
					if tokens.size() != 0 and k == PennyScript.Token.Type.TERMINATOR and tokens[-1].type == PennyScript.Token.Type.TERMINATOR:
						tokens[-1].value += token_match.get_string()

					else:
						tokens.push_back(PennyScript.Token.new(k, token_match))
						token_lines[tokens.back()] = line

						match k:
							PennyScript.Token.Type.INDENTATION:
								PennyScript.Token.compile_string_block_pattern(tokens.back().value)

							PennyScript.Token.Type.TERMINATOR:
								PennyScript.Token.compile_string_block_pattern(0)

			token_found = true
			cursor = (
				token_match.get_end()
				if token_match.get_end() != cursor
				else cursor + 1
			)
			break

		if token_found: continue

		result.raise_error("%s (ln %s, cl %s): Unrecognized token '%s'." % [
			file.get_path(),
			line,
			column,
			text[cursor],
		])

		for t in tokens:
			print(t)

		return


func statementize() -> void:
	var token_groups: Array[Array] = [[]]
	var group_index := 0
	for token in tokens:
		if token.type == PennyScript.Token.Type.TERMINATOR:
			if not token_groups[group_index].is_empty():
				token_groups.push_back([])
				group_index += 1
			continue

		token_groups[group_index].push_back(token)

	if token_groups[-1].is_empty():
		token_groups.pop_back()

	var stmt_head := StmtPass.new()
	stmt_head.owner = result
	stmt_head.owner_idx = 0
	var stmts: Array[Stmt] = [
		stmt_head,
	]

	for i in token_groups.size():
		var token_group := token_groups[i].duplicate()
		if token_group.is_empty(): continue

		var depth := 0
		if token_group[0].type == PennyScript.Token.Type.INDENTATION:
			depth = token_group.pop_front().value
			if token_group.is_empty(): continue

		var stmt: Stmt = get_stmt_from_token_group_destructive(token_group)
		assert(stmt != null, "No Stmt was created from token group: %s" % [
			token_groups[i]
		])

		stmt.owner = result
		stmt.owner_idx = stmts.size()
		stmt.code_address_line = token_lines[token_groups[i][0]]
		stmt.populate(token_group, depth)
		stmts.push_back(stmt)

	result.stmts = stmts

	for i in stmts.size():
		stmts[i].compile(result, i)

	if result.find_label_local(file_name) == null:
		result.label_addresses[file_name] = stmts[0]

	if OS.is_debug_build():
		# result.print_stmts()
		result.print_stmts(token_groups)



func get_stmt_from_token_group_destructive(group: Array) -> Stmt:
	if group.size() == 1:
		if group[0].type == PennyScript.Token.Type.OPERATOR:
				match group[0].value:
					PennyScript.Token.Operator.LESS_THAN:
						group.clear()
						return StmtDialogClose.new(true)

					PennyScript.Token.Operator.SUBTRACT:
						group.clear()
						return StmtDialogClose.new(false)


	var front_keywords: Array[PennyScript.Token.Keyword] = []
	while group and group[0].type == PennyScript.Token.Type.KEYWORD:
		front_keywords.push_back(group.pop_front().value)

	if front_keywords:
		match front_keywords[0]:
			PennyScript.Token.Keyword.CALL:
				return StmtCall.new()

			PennyScript.Token.Keyword.ELIF:
				return StmtElif.new()

			PennyScript.Token.Keyword.ELSE:
				return StmtElse.new()

			PennyScript.Token.Keyword.EXIT:
				return StmtExit.new()

			PennyScript.Token.Keyword.IF:
				return StmtIf.new()

			PennyScript.Token.Keyword.JUMP:
				return StmtJump.new()

			PennyScript.Token.Keyword.LABEL:
				return StmtLabel.new()

			PennyScript.Token.Keyword.MATCH:
				return StmtMatch.new()

			PennyScript.Token.Keyword.PASS:
				return StmtPass.new()

			PennyScript.Token.Keyword.PRINT:
				return StmtPrint.new()

			PennyScript.Token.Keyword.RETURN:
				return StmtReturn.new()

			PennyScript.Token.Keyword.SUSPEND:
				return StmtSuspend.new()

	for token in group:
		match token.type:
			PennyScript.Token.Type.ASSIGNMENT:
				return StmtAssign.new(StmtPath.get_declaration_type_from_front_keywords(front_keywords))

	match group.back().type:
		PennyScript.Token.Type.STRING_BLOCK, \
		PennyScript.Token.Type.STRING_QUOTED:
			return StmtDialog.new()

		PennyScript.Token.Type.OPERATOR:
			match group.back().value:
				PennyScript.Token.Operator.ACCESS:
					return StmtOption.new()

	if (
		group.front().type == PennyScript.Token.Type.IDENTIFIER
		or (
			group.front().type == PennyScript.Token.Type.IDENTIFIER
			and group.front().value == PennyScript.Token.Operator.DOT
		)
	):
			return StmtPath.new(StmtPath.get_declaration_type_from_front_keywords(front_keywords))

	return null
