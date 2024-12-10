
## Node that actualizes Penny statements. This stores local data_root and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.
class_name PennyHost extends Node

signal on_try_advance
signal on_data_modified
signal on_record_created(record: Record)
signal on_close
signal finished_execution

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

var records : Array[Record]
var call_stack : Array[Stmt]

var cursor : Stmt
var is_executing : bool = false

var last_valid_cursor : Stmt
var expecting_conditional : bool

var is_skipping : bool

## Returns the object in data that has most recently sent a message.
var last_dialog_object : PennyObject :
	get:
		for i in records.size():
			var record := records[-i-1]
			if record.stmt is StmtDialog:
				return record.stmt.subject_dialog_path.evaluate()
		return null


func _init() -> void:
	insts.push_back(self)


func _ready() -> void:
	PennyImporter.inst.on_reload_finish.connect(try_reload)

	for meta_name in self.get_meta_list():
		var meta : Variant = self.get_meta(meta_name)
		if meta is PennyDecoRegistry:
			var registry : PennyDecoRegistry = meta
			registry.register_decos()

	if autostart:
		jump_to.call_deferred(start_label)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() : return
	if event.is_action_pressed("penny_skip"):
		self.skip_to_next()
	# if event.is_action_pressed("penny_skip"):
	# 	is_skipping = true
	# elif event.is_action_released("penny_skip"):
	# 	is_skipping = false


# func _physics_process(delta: float) -> void:
# 	if is_skipping:
# 		skip_process()


func try_reload(success: bool) -> void:
	print("Try reload")
	if self.cursor:
		self.cursor.abort(self)
		self.last_valid_cursor = self.cursor
	self.cursor = null

	if self.last_valid_cursor:
		var start : Stmt = self.last_valid_cursor.owning_script.diff.remap_stmt_index(self.last_valid_cursor)
		self.last_valid_cursor = null
		if success:
			## TODO: Go back through the records till you find the new cursor, and undo stmts until that point.
			self.start_execution(start)


func perform_inits() -> void:
	for init in Penny.inits:
		await start_execution(init)


func _exit_tree() -> void:
	insts.erase(self)
	PennyObject.STATIC_ROOT.clear_instances_downstream(true)


func jump_to(label: StringName) -> void:
	self.abort()
	assert(cursor == null)
	start_execution(Penny.get_stmt_from_label(label))


func start_execution(at: Stmt) :
	assert(Penny.valid, "Penny.valid == false")
	cursor = at
	while cursor != null:
		var record : Record = await self.execute(cursor)
		if record.aborted:
			cursor = null
			break
		else:
			cursor = self.next(record)
	finished_execution.emit()


func execute(stmt : Stmt) :
	self.is_executing = true
	var result : Record = await stmt.execute(self)
	self.is_executing = false

	records.push_back(result)
	on_record_created.emit(result)

	return result


func abort() -> void:
	if cursor == null: return
	cursor.abort(self)


func skip_to_next() -> void:
	if cursor == null: return
	self.abort()
	assert(cursor == null)
	start_execution(next(records.back()))



func next(record : Record) -> Stmt:
	var result : Stmt = record.next()
	if result == null:
		if call_stack:
			return call_stack.pop_back()
		else:
			on_reach_end()
	return result


func try_advance() -> void:
	on_try_advance.emit()


func on_reach_end() -> void:
	close()


func close() -> void:
	on_close.emit()
	return


# func rewind_to(record: Record) -> void:
# 	expecting_conditional = false
# 	cursor = record.stmt
# 	while records.size() > record.stamp:
# 		records.pop_back().undo()
# 	execute()


func get_layer(i: int = -1) -> Node:
	if i < 0 or i >= layers.size(): return layers.back()
	return layers[i]
