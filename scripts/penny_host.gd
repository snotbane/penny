
## Node that actualizes Penny statements. Multiple of these can exist simultaneously. This is the main router from Penny script to visual scenes.
class_name PennyHost extends Node

var settings : PennySettings

var statement_index : Penny.Address
var statement : PennyParser.Statement :
	get: return Penny.get_statement_from_address(statement_index)

var is_blocked : bool = true

var message_receiver_parent_node : Node

var active_message_receiver : MessageReceiver

func _init(_label : StringName, _settings: PennySettings) -> void:
	settings = _settings
	statement_index = Penny.get_address_from_label(_label)
	print("*** LOADING PENNY AT LABEL: %s (%s)" % [_label, statement_index.path])

func _ready() -> void:
	message_receiver_parent_node = get_tree().root.find_child(settings.message_receiver_parent_node_name, true, false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		try_advance_via_input()

func advance() -> void:
	cleanup()

	statement_index.index += 1

	if statement == null:
		exit()
		return

	print("Advancing to %s" % statement_index)

	match statement.type:
		PennyParser.Statement.PRINT:
			print(statement.tokens[0].value)
		PennyParser.Statement.MESSAGE:
			message(statement)

	is_blocked = statement.is_blocking
	if not is_blocked:
		advance()

func cleanup() -> void:
	if active_message_receiver != null:
		active_message_receiver.queue_free()

func try_advance_via_input() -> bool:
	if is_blocked:
		advance()
		return true
	return false

func message(stmt: PennyParser.Statement) -> void:
	if active_message_receiver == null:
		active_message_receiver = settings.default_message_receiver_scene.instantiate()
		message_receiver_parent_node.add_child.call_deferred(active_message_receiver)

	active_message_receiver.receive(stmt.tokens[0].value)

func exit() -> void:
	print("*** EXITING PENNY IN FILE: %s" % statement_index.path)
	queue_free()
