
class_name StatementGeneric extends Object

enum Type {

}

# var address : Address
var depth : int
var tokens : Array[Token]
var line_in_file : int

var is_halting : bool :
	get: return false

var line_string : String :
	get: return "ln %s" % line_in_file

var action_string : String :
	get: return "INVALID"

func _init(_line_in_file: int, _depth: int) -> void:
	depth = _depth
	line_in_file = _line_in_file

func _to_string() -> String:
	var result := ""
	for i in tokens:
		result += str(i.value) + " "
	result = result.substr(0, result.length() - 1)
	result = "%s dp %s : %s (%s)" % [line_string, depth, result, action_string]
	return result

func _execute(host: PennyHost) -> Record:
	return null

func _undo(record: Record) -> void:
	pass

func validate() -> StatementGeneric:
	return null
