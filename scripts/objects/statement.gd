
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
		result += i.raw + " "
	return result.substr(0, result.length() - 1)

func get_prev(offset: int = 1) -> Statement :
	if address.index - offset < 0: return null
	return Penny.statements[address.path][address.index - offset]

func get_next(offset: int = 1) -> Statement :
	if address.index + offset >= Penny.statements.size(): return null
	return Penny.statements[address.path][address.index + offset]
