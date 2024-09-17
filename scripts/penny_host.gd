
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

class BlockingRecord:
	var statement: PennyParser.Statement

	func _init(stmt: PennyParser.Statement) -> void:
		statement = stmt

var _blocking_history : Array[BlockingRecord]
var blocking_history : Array[BlockingRecord] :
	get: return _blocking_history
	set (value):
		_blocking_history = value

var _blocking_history_index : int
var blocking_history_index : int :
	get: return _blocking_history_index
	set (value):
		if _blocking_history.is_empty(): return
		value = clamp(value, 0, _blocking_history.size() - 1)

		if _blocking_history_index == value: return
		_blocking_history_index = value

		invoke(_blocking_history[blocking_history_index].statement)

var settings : PennySettings

var statement_index : Penny.Address
var statement : PennyParser.Statement :
	get: return Penny.get_statement_from(statement_index)




var is_blocked : bool = false

var message_receiver_parent_node : Node

var active_message_receiver : MessageReceiver

func _init(_label : StringName, _settings: PennySettings) -> void:
	settings = _settings
	statement_index = Penny.get_address_from_label(_label)
	print("*** LOADING PENNY AT LABEL: %s (%s)" % [_label, statement_index.path])

func _ready() -> void:
	message_receiver_parent_node = get_tree().root.find_child(settings.message_receiver_parent_node_name, true, false)
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
	if is_blocked:
		advance()
		return true
	return false

func try_roll_back_via_input() -> bool:
	blocking_history_index += 1
	return true

func try_roll_forward_via_input() -> bool:
	blocking_history_index -= 1
	return true

func advance() -> void:
	statement_index.index += 1

	if statement == null:
		exit()
		return

	invoke(statement)
	record(statement)

	is_blocked = statement.is_blocking
	if not is_blocked:
		advance()

func cleanup() -> void:
	if active_message_receiver != null:
		active_message_receiver.queue_free()

## Actually do the thing that the statement is supposed to do based on type.
## Keeping this all in match for now to prevent any risk of mismatching statement types with incorrect methods. Any statement routed through here should be handled correctly.
func invoke(stmt: PennyParser.Statement) -> void:
	match stmt.type:
		PennyParser.Statement.PRINT:
			print(stmt.tokens[0].value)
		PennyParser.Statement.MESSAGE:
			cleanup()
			active_message_receiver = settings.default_message_receiver_scene.instantiate()
			message_receiver_parent_node.add_child.call_deferred(active_message_receiver)

			active_message_receiver.receive(Penny.Message.new(stmt))

## Record the statement as needed
func record(stmt: PennyParser.Statement) -> void:
	if stmt.is_blocking:
		blocking_history.push_front(BlockingRecord.new(stmt))

func exit() -> void:
	print("*** EXITING PENNY IN FILE: %s" % statement_index.path)
	queue_free()
