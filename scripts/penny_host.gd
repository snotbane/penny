
## Node that actualizes Penny statements. This stores local data and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.
class_name PennyHost extends Node

static var inst : PennyHost

var settings : PennySettings

var _cursor_address : Penny.Address
var cursor_address : Penny.Address :
	get: return _cursor_address
	set (value):
		if _cursor_address == value: return
		_cursor_address = value
		print("Cursor at %s" % cursor_address)

var cursor_statement : Penny.Statement :
	get: return Penny.get_statement_from(cursor_address)
	set (value):
		if cursor_address == value.address: return
		cursor_address = value.address

var history : Array[Penny.Record]

var is_halted : bool = false
var is_dumping : bool = false

var message_receiver_parent_node : Node

var active_message_receiver : MessageReceiver
var active_history_receiver : HistoryHandler

# func _init(_label : StringName, _settings: PennySettings) -> void:
# 	settings = _settings
# 	cursor_address = Penny.get_address_from_label(_label)
# 	print("*** LOADING PENNY AT LABEL: %s (%s)" % [_label, cursor_address.path])
func _init(__name: StringName = 'global') -> void:
	pass

func _ready() -> void:
	inst = self

	settings = load("res://addons/penny_godot/templates/default_settings.tres")
	cursor_address = Penny.get_address_from_label('test')
	print("*** LOADING PENNY AT LABEL: %s (%s)" % ['test', cursor_address.path])

	message_receiver_parent_node = get_tree().root.find_child(settings.message_receiver_parent_node_name, true, false)
	active_history_receiver = get_tree().root.find_child('penny_history_box', true, false)

	advance()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		try_advance_via_input()
	if event.is_action_pressed('penny_skip'):
		dump()
	# if settings.allow_roll_controls:
	# 	if event.is_action_pressed('penny_roll_back'):
	# 		try_roll_back_via_input()
	# 	if event.is_action_pressed('penny_roll_forward'):
	# 		try_roll_forward_via_input()

func try_advance_via_input() -> bool:
	if is_halted:
		advance()
		return true
	return false

# func try_roll_back_via_input() -> bool:
# 	roll_back()
# 	return true

# func try_roll_forward_via_input() -> bool:
# 	roll_forward()
# 	return true

# func roll_back() -> void:
# 	active_history_receiver.caret_halting_index -= 1

# func roll_forward() -> void:
# 	active_history_receiver.caret_halting_index += 1

func advance() -> void:
	print("\n")
	cursor_address.index += 1
	print("Cursor at %s" % cursor_address)

	if cursor_statement == null:
		exit()
		return

	invoke(cursor_statement)
	record(cursor_statement)

	if is_dumping:
		advance()
	else:
		is_halted = cursor_statement.is_halting
		if is_halted:
			active_history_receiver.caret_index = 1000
		else:
			advance()

func rewind_to(rec: Penny.Record) -> void:
	print("Rewinding to %s" % rec)
	cursor_address = rec.statement.address
	cursor_address.index -= 1
	history.resize(rec.stamp)
	active_history_receiver.resize_records(rec.stamp)
	print_history()
	cursor_address = rec.statement.address
	advance()
	#
	# for i in history.size():
	# 	if rec.equals(history[i]):
	# 		cursor_address = rec.statement.address
	# 		cursor_address.index -= 1
	# 		history.resize(i)
	# 		active_history_receiver.resize_records(i)
	# 		print("Cursor at %s" % cursor_address)
	# 		advance()
	# 		return
	# pass

func print_history() -> void:
	print("History:")
	for i : Penny.Record in history:
		print(i)

func dump() -> void:
	is_dumping = true
	advance()

func cleanup() -> void:
	if active_message_receiver != null:
		active_message_receiver.queue_free()

## Actually do the thing that the cursor_statement is supposed to do based on type.
## Keeping this all in match for now to prevent any risk of mismatching cursor_statement types with incorrect methods. Any cursor_statement routed through here should be handled correctly.
func invoke(stmt: Penny.Statement) -> void:
	match stmt.type:
		Penny.Statement.PRINT:
			print(stmt.tokens[0].value)
		Penny.Statement.MESSAGE:
			cleanup()
			active_message_receiver = settings.default_message_receiver_scene.instantiate()
			message_receiver_parent_node.add_child.call_deferred(active_message_receiver)

			active_message_receiver.receive(Penny.Message.new(stmt))

## Record the cursor_statement as needed
func record(stmt: Penny.Statement) -> void:
	var msg := Penny.Message.new(stmt)
	var rec := Penny.Record.new(self, history.size(), stmt, msg.text)
	history.push_back(rec)
	active_history_receiver.record(rec)
	pass

func exit() -> void:
	print("*** EXITING PENNY IN FILE: %s" % cursor_address.path)
	cleanup()
	queue_free()
