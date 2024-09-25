
## Single statement separated by newline or semicolon.
class_name Statement extends Object

enum {
	INVALID,

	# keyword standalone, require 0 parameters
	INIT,
	PASS,
	RISE,

	# keyword, optional 1 expression
	PRINT,
	RETURN,

	# keyword, require 1 identifier
	DIVE,
	LABEL,
	JUMP,

	# block require indentation
	BRANCH,			## IMPLICIT
	CONDITION,
	DECORATION,
	FILTER,
	MENU,
	OBJECT_MANIPULATE,

	## Miscellaneous
	ASSIGN,			## IMPLICIT
	MESSAGE,		## IMPLICIT
}

var type : int
var address : Address
var line : int
var depth : int
var tokens : Array[Token]

var is_halting : bool :
	get:
		match type:
			MESSAGE, MENU: return true
		return false

var is_record_user_facing : bool :
	get: return is_halting

func _init(_line: int, _depth: int, _address: Address) -> void:
	line = _line
	depth = _depth
	address = _address

func hash() -> int:
	return address.hash()

func equals(other: Statement) -> bool:
	return self.hash() == other.hash()

func debug_string() -> String:
	return "ln %s dp %s type %s : %s" % [line, depth, type, to_string()]

func _to_string() -> String:
	var result := ""
	for i in tokens:
		result += i.value + " "
	return result.substr(0, result.length() - 1)

func get_prev(offset: int = 1) -> Statement :
	if address.index - offset < 0: return null
	return Penny.statements[address.path][address.index - offset]

func get_next(offset: int = 1) -> Statement :
	if address.index + offset >= Penny.statements.size(): return null
	return Penny.statements[address.path][address.index + offset]

func add_token(token: Token) -> void:
	tokens.append(token)

func validate() -> bool:
	if tokens.size() == 0:
		PennyException.push_error(PennyException.PARSE_ERROR_UNCAUGHT_VALIDATION, [self])
		return false

	match tokens[0].type:
		Token.VALUE_STRING:
			if tokens.size() == 1:
				return validate_message_extension(MESSAGE)
			elif tokens.size() == 2:
				return validate_message_direct(MESSAGE)
		Token.KEYWORD:
			match tokens[0].value:
				"init": return validate_keyword_standalone(INIT)
				"pass": return validate_keyword_standalone(PASS)
				"rise": return validate_keyword_standalone(RISE)
				"print": return validate_keyword_with_optional_expression(PRINT)
				"return": return validate_keyword_with_optional_expression(RETURN)
				"dive": return validate_keyword_with_required_identifier(DIVE)
				"label": return validate_keyword_with_required_identifier(LABEL)
				"jump": return validate_keyword_with_required_identifier(JUMP)
				"elif", "else", "if": return validate_conditional(CONDITION)
				"object": return validate_keyword_standalone_with_required_block(OBJECT_MANIPULATE)
				"filter": return validate_keyword_standalone_with_required_block(FILTER)
		Token.IDENTIFIER:
			if tokens.size() == 1:
				return validate_object_manipulation(OBJECT_MANIPULATE)
			match tokens[1].type:
				Token.VALUE_STRING:
					return validate_message_direct(MESSAGE)
				Token.ASSIGNMENT:
					return validate_object_assignment(ASSIGN)

	PennyException.push_error(PennyException.PARSE_ERROR_UNCAUGHT_VALIDATION, [self])
	return false

func validate_keyword_standalone(expect: int) -> bool:
	type = expect
	if tokens.size() == 1:
		tokens = []
		return true
	else:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[1]])
		return false

func validate_keyword_with_optional_expression(expect: int) -> bool:
	type = expect
	tokens.pop_front()
	if tokens.size() == 0:
		return true
	return validate_expression(self, tokens)

func validate_keyword_with_required_expression(expect: int) -> bool:
	type = expect
	if tokens.size() == 1:
		PennyException.push_error(PennyException.PARSE_ERROR_EXPECTED_EXPRESSION, [line, tokens[0].col_end, tokens[0].value])
		return false
	tokens.pop_front()
	return validate_expression(self, tokens)

func validate_keyword_with_required_identifier(expect: int) -> bool:
	type = expect
	if tokens.size() == 1:
		PennyException.push_error(PennyException.PARSE_ERROR_EXPECTED_IDENTIFIER, [line, tokens[0].col_end, tokens[0].value])
		return false
	tokens.pop_front()
	if tokens.size() > 1:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[1]])
		return false
	if tokens[0].type != Token.IDENTIFIER:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[0]])
		return false
	return true

func validate_keyword_standalone_with_required_block(expect: int) -> bool:
	return validate_keyword_standalone(expect)

func validate_object_manipulation(expect: int) -> bool:
	type = expect
	return true

func validate_object_assignment(expect: int) -> bool:
	type = expect
	if tokens[1].value == 'is':
		if tokens.size() > 3:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[3]])
			return false
		if tokens[2].type != Token.IDENTIFIER && tokens[2].value != 'object':
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[2]])
			return false
		return true
	else:
		var expr := tokens
		expr.pop_front()
		expr.pop_front()
		return validate_expression(self, expr)

func validate_message_direct(expect: int) -> bool:
	type = expect
	if tokens.size() > 2:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[2]])
		return false
	if tokens[0].type != Token.IDENTIFIER && tokens[0].type != Token.VALUE_STRING:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[0]])
		return false
	if tokens[1].type != Token.VALUE_STRING:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[1]])
		return false
	return true

func validate_message_extension(expect: int) -> bool:
	type = expect
	if tokens.size() != 1:
		PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [tokens[1]])
		return false
	return true

func validate_conditional(expect: int) -> bool:
	type = expect
	var expr := tokens
	expr.pop_front()
	return validate_expression(self, expr)


static func validate_expression(ref: Statement, _tokens: Array[Token]) -> bool:
	if _tokens.size() == 0:
		PennyException.push_error(PennyException.PARSE_ERROR_EXPECTED_EXPRESSION, [ref.line, 0, ref._tokens[0].value])
		return false
	for i in _tokens.size():
		if not _tokens[i].belongs_in_expression_variant:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [_tokens[i]])
			return false
	return true

static func validate_boolean_expression(ref: Statement, _tokens: Array[Token]) -> bool:
	if _tokens.size() == 0:
		PennyException.push_error(PennyException.PARSE_ERROR_EXPECTED_EXPRESSION, [ref.line, 0, ref._tokens[0].value])
		return false
	for i in _tokens.size():
		if not _tokens[i].belongs_in_expression_variant:
			PennyException.push_error(PennyException.PARSE_ERROR_UNEXPECTED_TOKEN, [_tokens[i]])
			return false
	return true
