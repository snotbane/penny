
## Node that actualizes Penny statements. This stores local data and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.

## Penny starts by printing things to the history.

class_name PennyHost extends Node

var cursor : Address = null

var cursor_stmt : Statement :
	get: return Penny.get_statement_from(cursor)
	set (value):
		cursor = value.address

var records : Array[Record]

func _ready() -> void:
	jump_to('start')

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		advance()

func jump_to(label: StringName) -> void:
	cursor = Penny.get_address_from_label(label)
	advance()

func advance() -> void:
	if cursor == null:
		printerr("%s cannot advance because the cursor has not been assigned; check your labels." % self)
		return

	var record := Record.new(self, records.size(), cursor_stmt)
	records.push_back(record)



