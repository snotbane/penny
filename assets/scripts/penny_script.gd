
@tool
class_name PennyScript extends Resource

static var LINE_FEED_REGEX := RegEx.create_from_string(r"\n")

@export_storage var id : int
@export_storage var stmts : Array[Stmt] = []
@export_storage var errors : Array[String] = []

func _init(path : String) -> void:
	id = hash(path)


func update_from_file(file: FileAccess) -> void:
	errors.clear()

	var tokens := parse_code_to_tokens(file.get_as_text(true), file)
	# print(tokens)

	# var old_stmts : Array[Stmt]
	# if not Engine.is_editor_hint():
	# 	old_stmts = stmts.duplicate()

	parse_tokens_to_stmts(tokens, file)


func parse_tokens_to_stmts(tokens: Array[Token], context_file: FileAccess = null) -> void:
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

	stmts.clear()
	stmts.resize(token_groups.size())
	var offset := 0
	for i in token_groups.size():
		var j := i - offset
		var stmt_temp := Stmt.new()
		stmt_temp.populate(self, j, token_groups[i])
		stmts[j] = recycle_stmt(stmt_temp, j, token_groups[i], context_file)
		if stmts[j]:
			stmts[j].populate_from_other(stmt_temp, token_groups[i])
		else:
			offset += 1


static func recycle_stmt(stmt: Stmt, index: int, tokens: Array, context_file: FileAccess = null) -> Stmt:
	if tokens[0].type == Token.Type.INDENTATION:
		tokens.pop_front()
		if tokens.size() == 0: return null

	for token in tokens: if token.type == Token.Type.ASSIGNMENT: return StmtAssign.new()

	if tokens.front().type == Token.Type.KEYWORD:
		var keyword : StringName = tokens.pop_front().value
		match keyword:
			&"await":	return StmtAwait.new()
			&"call": 	return StmtJumpCall.new()
			&"close": 	return StmtClose.new()
			&"else": 	return StmtConditionalElse.new()
			&"elif": 	return StmtConditionalElif.new()
			&"if": 		return StmtConditionalIf.new()
			&"init":	return StmtInit.new()
			&"jump": 	return StmtJump.new()
			&"label": 	return StmtLabel.new()
			&"match": 	return StmtMatch.new()
			&"menu": 	return StmtMenu.new()
			&"open": 	return StmtOpen.new()
			&"pass": 	return StmtPass.new()
			&"print": 	return StmtPrint.new()
			&"return":	return StmtReturn.new()
		printerr("The keyword '%s' was found, but it isn't assigned to any Stmt." % keyword)
		return null

	var block_header := stmt.get_prev_in_lower_depth()
	if block_header:
		if block_header is StmtMatch:
			return StmtConditionalMatch.new()
		elif block_header is StmtMenu:
			return StmtConditionalMenu.new()

	if tokens.back().type == Token.Type.VALUE_STRING:
		return StmtDialog.new()

	match tokens.front().type:
		Token.Type.IDENTIFIER:
			if tokens.size() == 1 or (tokens[1].value is Expr.Op and tokens[1].value.type == Expr.Op.DOT):
				return StmtCell.new()
		Token.Type.OPERATOR:
			if tokens.front().value.type == Expr.Op.DOT and tokens[1].type == Token.Type.IDENTIFIER:
				return StmtCell.new()

	printerr("No Stmt recycled from tokens: %s" % str(tokens))
	return null

static func parse_code_to_tokens(raw: String, context_file: FileAccess = null) -> Array[Token]:
	var result : Array[Token] = []

	## If this gets stuck in a loop, Token.TYPE_PATTERNS has a regex pattern that matches with something of 0 length, e.g. ".*"
	var cursor := 0
	while cursor < raw.length():
		var rx_found = false
		var i := -1
		for k in Token.TYPE_PATTERNS.keys():
			i += 1
			var rx = Token.TYPE_PATTERNS[k].search(raw, cursor)
			if rx == null or rx.get_start() != cursor:
				continue
			rx_found = true

			match i:
				Token.Type.WHITESPACE, Token.Type.COMMENT:
					pass
				_:
					cursor = rx.get_start()

					var value : Variant = rx.get_string()
					match i:
						Token.Type.VALUE_STRING:
							value = rx.get_string()

					var token = Token.new(i, value)
					result.push_back(token)

			cursor = rx.get_end()
			break

		if not rx_found:
			var address_numbers := get_line_and_column_numbers(cursor, raw)
			if context_file:
				printerr("%s (ln %s, cl %s): Unrecognized token '%s'." % [context_file.get_path(), raw[cursor], address_numbers[0], address_numbers[1]])
			else:
				printerr("Unrecognized token '%s' at (ln %s, cl %s)." % [raw[cursor], address_numbers[0], address_numbers[1]])
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


class Token extends RefCounted:
	enum Type {
		INDENTATION,
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
	static var TYPE_PATTERNS := {
		Token.Type.INDENTATION: 			RegEx.create_from_string(r"(?m)^\t+"),
		Token.Type.VALUE_STRING: 			RegEx.create_from_string(r"(?s)([`'\"]).*?\1"),
		Token.Type.KEYWORD: 				RegEx.create_from_string(r"\b(await|call|close|else|elif|if|init|jump|label|match|menu|open|pass|print|return)\b"),
		Token.Type.VALUE_BOOLEAN: 			RegEx.create_from_string(r"\b([Tt]rue|TRUE|[Ff]alse|FALSE)\b"),
		Token.Type.VALUE_COLOR: 			RegEx.create_from_string(r"(?i)#(?:[0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{3,4})(?![0-9a-f])"),
		Token.Type.ASSIGNMENT: 				RegEx.create_from_string(r"=>|([+\-*/]?)=(?!=)"),
		Token.Type.OPERATOR: 				Expr.Op.PATTERN_COMPILED,
		Token.Type.COMMENT: 				RegEx.create_from_string(r"(?ms)(([#/])\*.*?(\*\2))|((#|\/{2}).*?$)"),
		Token.Type.IDENTIFIER: 				RegEx.create_from_string(r"[a-zA-Z_]\w*"),
		Token.Type.VALUE_NUMBER: 			RegEx.create_from_string(r"\d+\.\d*|\.?\d+"),
		Token.Type.TERMINATOR: 				RegEx.create_from_string(r"(?m)[:;]|((?<!\[)(?<=[^\n:;])$\n(?!\]))"),
		Token.Type.WHITESPACE: 				RegEx.create_from_string(r"(?m)[ \n]+|(?<!^|\t)\t+"),
	}

	enum Literal {
		STRING,
		COLOR,
		NULL,
		BOOLEAN_TRUE,
		BOOLEAN_FALSE,
		NUMBER_DECIMAL,
		NUMBER_INTEGER,
	}
	static var LITERAL_PATTERNS := {
		Literal.STRING: 			RegEx.create_from_string(r"(?s)(?<=([`'\"])).*?(?=\1)"),
		Literal.COLOR: 				TYPE_PATTERNS[Token.Type.VALUE_COLOR],
		Literal.NULL: 				RegEx.create_from_string(r"\b([Nn]ull|NULL)\b"),
		Literal.BOOLEAN_TRUE: 		RegEx.create_from_string(r"\b([Tt]rue|TRUE)\b"),
		Literal.BOOLEAN_FALSE: 		RegEx.create_from_string(r"\b([Ff]alse|FALSE)\b"),
		Literal.NUMBER_DECIMAL: 	RegEx.create_from_string(r"\b(\d+\.\d+|\d+\.|\.\d+)\b"),
		Literal.NUMBER_INTEGER: 	RegEx.create_from_string(r"\b\d+\b"),
	}
	static func parse_code_as_literal(raw: String) -> Variant:
		for i in LITERAL_PATTERNS.size():
			var rx : RegExMatch = LITERAL_PATTERNS[i].search(raw)
			if rx: match i:
				Literal.STRING:			return rx.get_string()
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
				value = Expr.Op.new_from_string(_raw)
			_:
				value = Token.parse_code_as_literal(_raw)


	func _to_string() -> String:
		var token_type_string : String
		match type:
			Token.Type.INDENTATION: token_type_string = "indent"
			Token.Type.VALUE_STRING: token_type_string = "string"
			Token.Type.KEYWORD: token_type_string = "keyword"
			Token.Type.VALUE_BOOLEAN: token_type_string = "boolean"
			Token.Type.VALUE_COLOR: token_type_string = "color"
			Token.Type.VALUE_NUMBER: token_type_string = "number"
			Token.Type.OPERATOR: token_type_string = "operator"
			Token.Type.COMMENT: token_type_string = "comment"
			Token.Type.ASSIGNMENT: token_type_string = "assigner"
			Token.Type.IDENTIFIER: token_type_string = "identifier"
			Token.Type.TERMINATOR: token_type_string = "terminator"
			Token.Type.WHITESPACE: token_type_string = "whitespace"
			_: token_type_string = "invalid_token"
		return "%s:%s" % [token_type_string, str(value)]
