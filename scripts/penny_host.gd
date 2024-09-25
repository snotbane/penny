
## Node that actualizes Penny statements. This stores local data and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.

## Penny starts by printing things to the history.

class_name PennyHost extends Node

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

var history_handler : HistoryHandler

var records : Array[Record]

var is_halting : bool :
	get: return cursor_stmt.is_halting

func _ready() -> void:
	history_handler = get_tree().root.find_child('penny_history_box', true, false)
	jump_to('start')

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		advance()

func jump_to(label: StringName) -> void:
	cursor = Penny.get_address_from_label(label)
	invoke_at_cursor()

func invoke_at_cursor() -> void:
	var rec := Record.new(self, records.size(), cursor_stmt)
	records.push_back(rec)
	history_handler.receive(rec)

	if is_halting:
		pass
	else:
		advance()

func advance() -> void:
	cursor.index += 1
	invoke_at_cursor()

func rewind_to(rec: Record) -> void:
	cursor = rec.address
	print("Rewinding to %s" % cursor)
	while records.size() > rec.stamp:
		records.pop_back()
	history_handler.rewind_to(rec)
	invoke_at_cursor()
