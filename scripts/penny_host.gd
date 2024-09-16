
## Node that actualizes Penny statements. Multiple of these can exist simultaneously. This is the main router from Penny script to visual scenes.
class_name PennyHost extends Node

var statement_index : Penny.Address
var statement : PennyParser.Statement :
	get: return Penny.get_statement_from_address(statement_index)

var is_blocked : bool = false

func _init(_label : StringName) -> void:
	statement_index = Penny.get_address_from_label(_label)
	print("*** LOADING PENNY AT LABEL: %s (%s)" % [_label, statement_index.path])
	advance()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		try_advance_via_input()

func advance() -> void:
	statement_index.index += 1


	if statement == null:
		exit()
		return

	print("Advancing to %s , %s" % [statement_index, statement.debug_string()])

	match statement.type:
		PennyParser.Statement.PRINT:
			print(statement.tokens[0].value)
		PennyParser.Statement.MESSAGE:
			print(statement.tokens[0].value)

	is_blocked = statement.is_blocking
	if not is_blocked:
		advance()

func try_advance_via_input() -> bool:
	if is_blocked:
		advance()
		return true
	return false

func exit() -> void:
	print("*** EXITING PENNY IN FILE: %s" % statement_index.path)
	queue_free()
