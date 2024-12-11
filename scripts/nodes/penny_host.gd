
## Node that actualizes Penny statements. This stores local data_root and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.
class_name PennyHost extends Node

class History:

	signal records_changed

	var records : Array[Record]
	var max_size : int = -1

	var last : Record :
		get: return records.back()


	var last_dialog : Record :
		get:
			for i in records.size():
				var record := records[-i-1]
				if record.stmt is StmtDialog:
					return record
			return null


	func _init(_max_size : int = -1) -> void:
		max_size = _max_size


	func get_reverse(i : int) -> Record:
		return records[-i-1]


	func add(record: Record) -> void:
		records.push_back(record)

		if max_size >= 0:
			while records.size() > max_size:
				records.pop_front()

		records_changed.emit()


	func reset_at(index : int) -> void:
		for i in index:
			records.pop_back()
		if index > 0:
			records_changed.emit()



signal on_try_advance
signal on_data_modified
signal on_record_created(record: Record)
signal on_close
signal finished_execution

signal on_roll_back_disabled(value : bool)
signal on_roll_ahead_disabled(value : bool)

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

@export var allow_rolling := true

static var insts : Array[PennyHost] = []

var call_stack : Array[Stmt]

var cursor : Stmt
var is_executing : bool = false

var last_valid_cursor : Stmt
var expecting_conditional : bool

var is_skipping : bool

## Returns the object in data that has most recently sent a message.
var last_dialog_object : PennyObject :
	get:
		var last_dialog := history.last_dialog
		if last_dialog: return last_dialog.stmt.subject_dialog_path.evaluate()
		return null


var history : History

var _history_cursor_index : int = 0
@export var history_cursor_index : int = 0 :
	get: return _history_cursor_index
	set(value):
		value = clamp(value, 0, history.records.size() - 1)
		if _history_cursor_index == value: return

		self.abort()

		_history_cursor_index = value

		emit_roll_events()

		self.execute(history_cursor, false)

var history_cursor : Stmt :
	get:
		# if _history_cursor_index == -1: return next(history.last)
		return history.get_reverse(_history_cursor_index).stmt


var can_roll_back : bool :
	get: return history_cursor_index < history.records.size() - 1


var can_roll_ahead : bool :
	get: return history_cursor_index > 0


func _init() -> void:
	insts.push_back(self)

	history = History.new()


func _ready() -> void:
	PennyImporter.inst.on_reload_finish.connect(try_reload)

	for meta_name in self.get_meta_list():
		var meta : Variant = self.get_meta(meta_name)
		if meta is PennyDecoRegistry:
			var registry : PennyDecoRegistry = meta
			registry.register_decos()

	if autostart:
		jump_to.call_deferred(start_label)

	history.records_changed.connect(self.emit_roll_events)
	emit_roll_events()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() : return
	if event.is_action_pressed("penny_skip"):
		self.skip_to_next()
	# if event.is_action_pressed("penny_skip"):
	# 	is_skipping = true
	# elif event.is_action_released("penny_skip"):
	# 	is_skipping = false
	elif event.is_action_pressed("penny_roll_back"):
		roll_back()
	elif event.is_action_pressed("penny_roll_ahead"):
		roll_ahead()


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
			execute(start)


func perform_inits() -> void:
	for init in Penny.inits:
		await execute(init)


func _exit_tree() -> void:
	insts.erase(self)
	PennyObject.STATIC_ROOT.clear_instances_downstream(true)


func jump_to(label: StringName) -> void:
	self.abort()
	assert(cursor == null)
	execute(Penny.get_stmt_from_label(label))


func execute(stmt : Stmt, create_record: bool = true) :
	if stmt == null: return

	self.is_executing = true
	var record : Record = await stmt.execute(self)
	self.is_executing = false

	if create_record:
		history.reset_at(history_cursor_index)
		history.add(record)
		on_record_created.emit(record)

	if record.aborted:
		cursor = null
	else:
		cursor = self.next(record)
		self.execute(cursor, true)

func abort() -> void:
	if cursor == null: return
	cursor.abort(self)


func skip_to_next() -> void:
	if history_cursor_index > 0:
		roll_ahead()
		return

	if cursor == null: return
	self.abort()
	execute(next(history.last))


func roll_ahead() -> void:
	if not allow_rolling or not can_roll_ahead: return
	history_cursor_index -= 1
	print("roll_ahead (%s)" % history_cursor_index)


func roll_back() -> void:
	if not allow_rolling or not can_roll_back: return
	history_cursor_index += 1
	print("roll_back (%s)" % history_cursor_index)


func reset_history(at : int = history_cursor_index) -> void:
	_history_cursor_index = 0
	history.reset_at(at)


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


func emit_roll_events() -> void:
	on_roll_ahead_disabled.emit(not can_roll_ahead)
	on_roll_back_disabled.emit(not can_roll_back)
