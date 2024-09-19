
## Node that actualizes Penny statements. Multiple of these can exist simultaneously. This is the main router from Penny script to visual scenes.
class_name PennyHost extends Node

# class AssignmentRecord:
# 	var address: Penny.Address
# 	var key: StringName
# 	var before: Variant
# 	var after: Variant

# var _history : Array[AssignmentRecord]
# var history : Array[AssignmentRecord] :
# 	get: return _history
# 	set(value):
# 		_history = value
# 		while _history.size() > settings.roll_history_max_size:
# 			_history.pop_front()

# var _history_index : int
# var history_index : int :
# 	get: return _history_index
# 	set (value):
# 		if _history.is_empty(): return
# 		value = clamp(value, 0, _history.size() - 1)

# class HaltRecord:
# 	var statement: Penny.Statement

# 	func _init(stmt: Penny.Statement) -> void:
# 		statement = stmt

# var _halt_history : Array[HaltRecord]
# var halt_history : Array[HaltRecord] :
# 	get: return _halt_history
# 	set (value):
# 		_halt_history = value

# var _halt_history_index : int
# var halt_history_index : int :
# 	get: return _halt_history_index
# 	set (value):
# 		if _halt_history.is_empty(): return
# 		value = clamp(value, 0, _halt_history.size() - 1)

# 		if _halt_history_index == value: return
# 		_halt_history_index = value

# 		invoke(_halt_history[halt_history_index].statement)

## The particular set of statements that the player chooses to go down.
var statement_history : Array[Penny.Statement]

var _statement_history_index : int
var statement_history_index : int :
	get: return _statement_history_index
	set (value):
		if statement_history.is_empty(): return
		value = clamp(value, 0, statement_history.size() - 1)
		if _statement_history_index == value: return
		_statement_history_index = value

		statement_index = statement_history[statement_history.size() - 1 - statement_history_index].address
		invoke(statement)



var settings : PennySettings

var _statement_index : Penny.Address
var statement_index : Penny.Address :
	get: return _statement_index
	set (value):
		if _statement_index == value: return
		_statement_index = value

var statement : Penny.Statement :
	get: return Penny.get_statement_from(statement_index)
	set (value):
		if statement_index == value.address: return
		statement_index = value.address

var is_halted : bool = false

var message_receiver_parent_node : Node

var active_message_receiver : MessageReceiver
var active_history_receiver : HistoryHandler

func _init(_label : StringName, _settings: PennySettings) -> void:
	settings = _settings
	statement_index = Penny.get_address_from_label(_label)
	print("*** LOADING PENNY AT LABEL: %s (%s)" % [_label, statement_index.path])

func _ready() -> void:
	message_receiver_parent_node = get_tree().root.find_child(settings.message_receiver_parent_node_name, true, false)
	active_history_receiver = get_tree().root.find_child('penny_history_box', true, false)
	advance()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		try_advance_via_input()
	if settings.allow_roll_controls:
		if event.is_action_pressed('penny_roll_back'):
			try_roll_back_via_input()
		if event.is_action_pressed('penny_roll_forward'):
			try_roll_forward_via_input()

func try_advance_via_input() -> bool:
	if is_halted:
		advance()
		return true
	return false

func try_roll_back_via_input() -> bool:
	roll_back()
	return true

func try_roll_forward_via_input() -> bool:
	roll_forward()
	return true

func advance() -> void:
	reset_history()

	statement_index.index += 1

	if statement == null:
		exit()
		return

	invoke(statement)
	record(statement)

	is_halted = statement.is_halting
	if not is_halted:
		advance()

func roll_back() -> void:
	statement_history_index += 1

	is_halted = statement.is_halting
	if not is_halted:
		roll_back()

func roll_forward() -> void:
	statement_history_index -= 1

	is_halted = statement.is_halting
	if not is_halted:
		roll_forward()

func reset_history() -> void:
	statement_history.resize(statement_history.size() - statement_history_index)
	_statement_history_index = 0

func cleanup() -> void:
	if active_message_receiver != null:
		active_message_receiver.queue_free()

## Actually do the thing that the statement is supposed to do based on type.
## Keeping this all in match for now to prevent any risk of mismatching statement types with incorrect methods. Any statement routed through here should be handled correctly.
func invoke(stmt: Penny.Statement) -> void:
	match stmt.type:
		Penny.Statement.PRINT:
			print(stmt.tokens[0].value)
		Penny.Statement.MESSAGE:
			cleanup()
			active_message_receiver = settings.default_message_receiver_scene.instantiate()
			message_receiver_parent_node.add_child.call_deferred(active_message_receiver)

			active_message_receiver.receive(Penny.Message.new(stmt))

## Record the statement as needed
func record(stmt: Penny.Statement) -> void:
	active_history_receiver.record(stmt)
	pass

func exit() -> void:
	print("*** EXITING PENNY IN FILE: %s" % statement_index.path)
	cleanup()
	queue_free()
