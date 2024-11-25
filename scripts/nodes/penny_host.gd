
## Node that actualizes Penny statements. This stores local data_root and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.
class_name PennyHost extends Node

enum State {
	UNLOADED,
	INITING,
	READY
}

signal on_try_advance
signal on_data_modified
signal on_record_created(record: Record)
signal on_close

@export_subgroup("Instantiation")

## Lookup tables.
@export var lookup_tables : Array[LookupTable]

## [PennyNode]s instantiated via script will be added to their preferred layer, else the last in this list. Require at least one element. Any node/space can be used.
@export var layers : Array[Node]

@export_subgroup("Flow")

## If enabled, the host will begin execution on ready.
@export var autostart := false

## The label in Penny scripts to start at. Make sure this is populated with a valid label.
@export var start_label := StringName('start')

static var insts : Array[PennyHost] = []

var state := State.UNLOADED
var data_root := PennyObject.STATIC_ROOT

var records : Array[Record]
var call_stack : Array[Stmt]

var cursor : Stmt
var expecting_conditional : bool

var is_skipping : bool

## Returns the object in data that has most recently sent a message.
var last_dialog_object : PennyObject :
	get:
		for i in records.size():
			var record := records[-i-1]
			if record.stmt is StmtDialog:
				return record.stmt.subject_dialog_path.evaluate(self.data_root)
		return null

var valid : bool :
	get: return Penny.valid and cursor != null

func _init() -> void:
	insts.push_back(self)


func _ready() -> void:
	PennyImporter.inst.on_reloaded.connect(reload)

	for meta_name in self.get_meta_list():
		var meta : Variant = self.get_meta(meta_name)
		if meta is PennyDecoRegistry:
			var registry : PennyDecoRegistry = meta
			registry.register_scripts()

	if autostart:
		PennyImporter.inst.on_reloaded.connect(start_at_label, ConnectFlags.CONNECT_ONE_SHOT)


func start_after_reload(bookmark: Stmt) -> void:
	# self.start_at_stmt(bookmark) # This doesn't work, it just repeats the same statement without updating changes. Obviously.
	# for i in records.size():
	# 	var record_stmt := records[records.size() - (i + 1)].stmt
	# 	var match := Penny.find_stmt_by_hash_id(record_stmt)
	# 	if match:
	# 		self.start_at_stmt(match)
	# 		return
	self.start_at_label()



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("penny_skip"):
		is_skipping = true
	elif event.is_action_released("penny_skip"):
		is_skipping = false


func _physics_process(delta: float) -> void:
	if is_skipping:
		skip_process()


func start_at_stmt(stmt: Stmt) -> void:
	self.cursor = stmt
	if not self.valid: return
	self.invoke_at_cursor()


func start_at_label(label: StringName = self.start_label) -> void:
	self.start_at_stmt(Penny.get_stmt_from_label(label))


func reload() -> void:
	var cursor_bookmark := cursor
	cursor = null

	state = State.UNLOADED
	if not Penny.valid: return

	state = State.INITING
	for init in Penny.inits:
		cursor = init
		invoke_at_cursor()
	cursor = null

	state = State.READY
	if cursor_bookmark:
		start_after_reload(cursor_bookmark)


func _exit_tree() -> void:
	insts.erase(self)
	data_root.destroy_instance_downstream(self, true)


func jump_to(label: StringName) -> void:
	cursor = Penny.get_stmt_from_label(label)
	invoke_at_cursor()


func invoke_at_cursor() -> void:
	var record := cursor.execute(self)

	records.push_back(record)
	on_record_created.emit(record)

	if not record.halt or state == State.INITING:
		advance()


func try_advance() -> void:
	on_try_advance.emit()


func advance() -> void:
	if not self.valid: return
	cursor = records.back().next()
	if cursor == null:
		if call_stack:
			cursor = call_stack.pop_back()
		else:
			on_reach_end()
			return
	invoke_at_cursor()


func skip_process() -> void:
	if records.back().stmt is StmtDialog:
		advance()


func on_reach_end() -> void:
	match state:
		State.READY:
			close()


func close() -> void:
	on_close.emit()
	queue_free()
	return


func rewind_to(record: Record) -> void:
	expecting_conditional = false
	cursor = record.stmt
	while records.size() > record.stamp:
		records.pop_back().undo()
	invoke_at_cursor()


func get_layer(i: int = -1) -> Node:
	if i < 0 or i >= layers.size(): return layers.back()
	return layers[i]
