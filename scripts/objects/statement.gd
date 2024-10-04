
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
	CONDITION_IF,
	CONDITION_ELIF,
	CONDITION_ELSE,
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

var line_string : String :
	get: return "ln %s" % line

func _init(_line: int, _depth: int, _address: Address) -> void:
	line = _line
	depth = _depth
	address = _address

func hash() -> int:
	return address.hash()

func equals(other: Statement) -> bool:
	return self.hash() == other.hash()

func _to_string() -> String:
	var result := ""
	for i in tokens:
		result += str(i.value) + " "
	result = result.substr(0, result.length() - 1)
	result = "%s dp %s : %s (%s)" % [line_string, depth, result,  enum_to_string(type)]
	return result

static func enum_to_string(idx: int) -> String:
	match idx:
		INIT: return "init"
		PASS: return "pass"
		RISE: return "rise"
		PRINT: return "print"
		RETURN: return "return"
		DIVE: return "dive"
		LABEL: return "label"
		JUMP: return "jump"
		BRANCH: return "branch"
		CONDITION_IF: return "if"
		CONDITION_ELIF: return "elif"
		CONDITION_ELSE: return "else"
		DECORATION: return "decoration"
		FILTER: return "filter"
		MENU: return "menu"
		OBJECT_MANIPULATE: return "object_manipulate"
		ASSIGN: return "assign"
		MESSAGE: return "message"
		_: return "invalid"

func execute(host: PennyHost) -> Record:
	var result : Record
	match type:
		Statement.CONDITION_IF, Statement.CONDITION_ELIF, Statement.CONDITION_ELSE:
			result = Record.new(host, self, host.evaluate_expression(tokens))
		Statement.MESSAGE:
			result = Record.new(host, self)
			host.message_handler.receive(result)
		Statement.ASSIGN:
			var key : StringName = tokens[0].value
			var before : Variant = host.data.get_data(key)
			var eval = host.evaluate_expression(tokens, 2)
			if eval is PennyObject:
				host.data.add_object(key, tokens[2].value)
			else:
				host.data.set_data(key, eval)
			var after : Variant = host.data.get_data(key)
			result = Record.new(host, self, AssignmentRecord.new(key, before, after))
		_:
			result = Record.new(host, self)
	return result

func exception(s: String) -> PennyException:
	return PennyException.new("%s : \n\t%s" % [line_string, s])

func validate() -> PennyException:
	if tokens.is_empty():
		return exception("Statement is empty (no tokens).")
	match tokens[0].type:
		Token.VALUE_STRING:
			type = Statement.MESSAGE
			return validate_message()
		Token.KEYWORD:
			match tokens[0].value:
				'print':
					type = Statement.PRINT
					return validate_keyword_with_expression()
				'label':
					type = Statement.LABEL
					return validate_keyword_with_identifier()
				'if':
					type = Statement.CONDITION_IF
					return validate_keyword_with_expression()
				'elif':
					type = Statement.CONDITION_ELIF
					return validate_keyword_with_expression()
				'else':
					type = Statement.CONDITION_ELSE
					return validate_keyword_with_none()
		Token.IDENTIFIER:
			if tokens.size() == 1:
				type = Statement.OBJECT_MANIPULATE
				# Throw uncaught exception for now
			for i in tokens.size():
				if tokens[i].type == Token.ASSIGNMENT:
					type = Statement.ASSIGN
					return validate_assignment(i)
	return exception("Uncaught exception for statement '%s'" % self)

func validate_keyword_with_none() -> PennyException:
	tokens.pop_front()
	if not tokens.is_empty():
		return exception("Statement requires keyword alone with no expression.")
	return null

func validate_keyword_with_expression(require: bool = true) -> PennyException:
	tokens.pop_front()
	if not require and tokens.is_empty():
		return null
	return validate_expression(tokens)

func validate_keyword_with_identifier(count: int = 1) -> PennyException:
	tokens.pop_front()
	if tokens.size() != count:
		return exception("Statement requires exactly %s tokens." % count)
	for i in tokens.size():
		if tokens[i].type == Token.IDENTIFIER: continue
		return exception("Unexpected token '%s' is not an identifier." % tokens[i])
	return null

func validate_message() -> PennyException:
	match tokens.size():
		1:
			if tokens[0].type != Token.VALUE_STRING:
				return exception("Message statements must contain a string.")
		2:
			if tokens[0].type != Token.IDENTIFIER:
				return exception("Message statements must start with an object identifier.")
			if tokens[1].type != Token.VALUE_STRING:
				return exception("Message statements must contain a string.")
		_:
			return exception("Unexpected token '%s'" % tokens[2])
	return null

func validate_assignment(separator: int) -> PennyException:
	var left := tokens.slice(0, separator)
	# print(left)
	var left_exception := validate_object_path(left)
	if left_exception:
		return left_exception

	var right := tokens.slice(separator + 1)
	# print(right)
	var right_exception := validate_expression(right)
	if right_exception:
		return right_exception

	var operator = tokens[separator]

	print("All tokens: ", tokens)
	return null

func validate_object_path(expr: Array[Token]) -> PennyException:
	if expr.size() & 1 == 0:
		return exception("Identifier chain expects an odd-numbered size.")
	for i in expr.size():
		var token = expr[i]
		if i & 1:
			if token.value != '.':
				return exception("Expected dot operator in identifier chain.")
		else:
			if token.type != Token.IDENTIFIER:
				return exception("Expected identifier before assignment operator.")
	return null

func validate_expression(expr: Array[Token]) -> PennyException:
	if expr.is_empty():
		return exception("Expression is empty.")
	return null
