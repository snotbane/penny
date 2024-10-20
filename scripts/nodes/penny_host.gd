
## Node that actualizes Penny statements. This stores local data_root and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.
class_name PennyHost extends Node

signal on_data_modified

@export_subgroup("Instantiation")

## Settings.
@export var settings : PennySettings

## Lookup tables.
@export var lookup_tables : Array[LookupTable]

## Controls instantiated via Penny will be added to this master [Control].
@export var instantiate_parent_control : Control

## Controls instantiated via Penny will be added to this master [Node2D].
@export var instantiate_parent_2d : Node2D

## Controls instantiated via Penny will be added to this master [Node3D].
@export var instantiate_parent_3d : Node3D


## Reference to a message handler. (Temporary. Eventually will be instantiated in code)
@export var message_handler : MessageHandler

## Reference to the history handler.
@export var history_handler : HistoryHandler

@export_subgroup("Flow")

## If populated, this host will start at this label on ready. Leave empty to not execute anything.
@export var autostart_label : StringName = ''



static var insts : Array[PennyHost] = []

var data_root := PennyObject.new(self, '_root', { PennyObject.BASE_OBJECT_NAME: PennyObject.BASE_OBJECT })
var records : Array[Record]

var call_stack : Array[Stmt_.Address]
var expecting_conditional : bool
var cursor : Stmt_

var is_halting : bool :
	get: return cursor.is_halting

@onready var watcher := Watcher.new([message_handler])

func _ready() -> void:
	insts.push_back(self)

	if Penny.valid and not autostart_label.is_empty():
		jump_to.call_deferred(autostart_label)

func _exit_tree() -> void:
	insts.erase(self)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		if not watcher.working:
			advance()
		else: watcher.wrap_up_work()

func jump_to(label: StringName) -> void:
	cursor = Penny.get_stmt_from_label(label)
	invoke_at_cursor()

func invoke_at_cursor() -> void:
	var record := cursor.execute(self)

	records.push_back(record)
	history_handler.receive(record)

	if is_halting:
		pass
	else:
		advance()

func advance() -> void:
	if cursor == null: return
	cursor = records.back().next()

	if cursor == null:
		if call_stack:
			cursor = call_stack.pop_back().stmt
		else:
			close()
			return

	invoke_at_cursor()

func close() -> void:
	message_handler.queue_free()
	queue_free()

func rewind_to(record: Record) -> void:
	expecting_conditional = false
	cursor = record.stmt
	while records.size() > record.stamp:
		records.pop_back().undo()
	history_handler.rewind_to(record)

	invoke_at_cursor()
