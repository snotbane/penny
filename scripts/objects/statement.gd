
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
	var result := enum_to_string(type) + " "
	for i in tokens:
		result += i.raw + " "
	return result.substr(0, result.length() - 1)

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
		DECORATION: return "decor"
		FILTER: return "filter"
		MENU: return "menu"
		OBJECT_MANIPULATE: return "obj"
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
		_:
			result = Record.new(host, self)
	return result
