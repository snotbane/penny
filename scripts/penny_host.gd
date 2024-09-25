
## Node that actualizes Penny statements. This stores local data and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.
class_name PennyHost extends Node

@export var start_label : StringName = 'start'
@export var message_handler : MessageHandler
@export var history_handler : HistoryHandler
@export var settings : PennySettings

var _cursor : Address = null
var cursor : Address = null :
	get: return _cursor
	set (value):
		if _cursor == null:
			if _cursor == value: return
		elif _cursor.equals(value): return
		else: _cursor.free()
		_cursor = value.copy()

var cursor_stmt : Statement :
	get: return Penny.get_statement_from(cursor)
	set (value):
		cursor = value.address


var records : Array[Record]

var is_halting : bool :
	get: return cursor_stmt.is_halting

var ready_to_advance : bool :
	get: return message_handler.ready_to_advance
	set (value):
		message_handler.ready_to_advance = value

@onready var watcher := Watcher.new([message_handler])

func _ready() -> void:
	if history_handler == null: return
	jump_to.call_deferred(start_label)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		if not watcher.working:
			advance()
		else: watcher.wrap_up_work()

func jump_to(label: StringName) -> void:
	cursor = Penny.get_address_from_label(label)
	invoke_at_cursor()

func invoke_at_cursor() -> void:
	var record := Record.new(self, records.size(), cursor_stmt)
	records.push_back(record)
	history_handler.receive(record)
	message_handler.receive(record)

	if is_halting:
		pass
	else:
		advance()

func advance() -> void:
	cursor.index += 1
	invoke_at_cursor()

func rewind_to(record: Record) -> void:
	cursor = record.address
	print("Rewinding to %s" % cursor)
	while records.size() > record.stamp:
		records.pop_back()
	history_handler.rewind_to(record)
	invoke_at_cursor()
