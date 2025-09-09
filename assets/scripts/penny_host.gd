
## Node that actualizes Penny statements. This stores local data_root and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.
class_name PennyHost extends HistoryUser

signal on_try_advance
signal on_data_modified
signal on_close
signal finished_execution

## If enabled, the host will begin execution on ready.
@export var autostart := false

## The label in Penny scripts to start at. Make sure this is populated with a valid label.
@export var start_label := &"start"

@export var allow_skipping := true
@export var allow_rolling := true

@export_subgroup("Debug")

@export var debug_log_stmts : bool

static var insts : Array[PennyHost] = []

var call_stack : Array[Stmt]

var cursor : Record

var last_valid_cursor : Record
var expecting_conditional : bool

var is_skipping : bool
var is_aborting : bool = false

## Returns the object in data that has most recently sent a message.
var last_dialog_object : Cell :
	get:
		var last_dialog := history.last_dialog
		if last_dialog: return last_dialog.stmt.subject_dialog_path.evaluate()
		return null

func _set_history_index(value: int) -> void:
	abort()

	var increment := signi(value - _history_index)
	while _history_index != value:
		if increment < 0:
			history_cursor.undo()
		elif increment > 0:
			history_cursor.redo()

		_history_index += increment

	execute_record(history_cursor)

func roll_ahead() -> void:
	if not allow_rolling: return

	super.roll_ahead()

func roll_back() -> void:
	if not allow_rolling: return

	super.roll_back()


func _init() -> void:
	insts.push_back(self)

	super._init()


func _exit_tree() -> void:
	insts.erase(self)


func _ready() -> void:
	Penny.inst.on_reload_finish.connect(try_reload)

	if autostart:
		jump_to.call_deferred(start_label)

	super._ready()


# func _physics_process(delta: float) -> void:
# 	if is_skipping:
# 		skip_process()


func try_reload(success: bool) -> void:
	if cursor:
		abort()
		cull_ahead_in_place()

	if last_valid_cursor:
		var start : Stmt = last_valid_cursor.stmt.owner.diff.remap_stmt_index(last_valid_cursor.stmt)
		if success:
			## TODO: Go back through the records till you find the new cursor, and undo stmts until that point.
			# last_valid_cursor.undo(history_cursor)
			last_valid_cursor = null
			create_record_and_execute(start)
		else:
			last_valid_cursor = null


func perform_inits() -> void:
	for init in Penny.inits:
		create_record_and_execute(init)


func perform_inits_selective(scripts: Array[PennyScript]) -> void:
	for init in Penny.inits:
		if not scripts.has(init.owner): continue
		create_record_and_execute(init)


func jump_to(label: StringName) -> void:
	abort()
	create_record_and_execute(Penny.get_stmt_from_label(label))


func call_to(label: StringName) -> void:
	call_stack.push_back(cursor.next_in_order)
	jump_to(label)


func create_record(stmt: Stmt) -> Record:
	if stmt == null: return null

	var result := stmt.prep(self)
	history.add(result)
	return result


## Creates a new record from the given [stmt] and then executes it.
func create_record_and_execute(stmt : Stmt) -> void:
	var record : Record = create_record(stmt)
	if not record: return

	_history_index = history.back_index
	execute_record(record)

## Executes an already existing record.
func execute_record(record: Record) :
	cursor = record
	last_valid_cursor = cursor

	if debug_log_stmts: print("%s %s" % [name, cursor.stmt.__debug_string__])

	var response : Stmt.ExecutionResponse = await cursor.stmt.execute(cursor)

	if response != Stmt.ExecutionResponse.FINISHED: return

	if is_at_present or cursor.force_cull_history:
		cursor.force_cull_history = false
		cull_ahead_in_place()
		var next__ = get_next_stmt(cursor)
		create_record_and_execute(next__)
	else:
		roll_ahead()

func abort() -> void:
	if cursor == null: return
	cursor.stmt.abort()


func user_skip() -> void:
	if not allow_skipping: return

	if is_at_present:
		if cursor and not cursor.stmt.is_skippable: return
		abort()
		create_record_and_execute(get_next_stmt(cursor))
	else:
		roll_ahead()


func get_next_stmt(record : Record) -> Stmt:
	var result : Stmt = record.next()
	if result == null:
		if call_stack:
			return call_stack.pop_back()
		else:
			close()
	return result


func close() -> void:
	on_close.emit()

#region Save/Load


class SaveData extends JSONFileResource:
	var host : PennyHost

	func _init(__host: PennyHost, __save_data__: String = generate_save_path()) -> void:
		host = __host
		super._init(__save_data__)

	func _export_json(json: Dictionary) -> void:
		json.merge({
			&"git_rev_penny": PennyUtils.get_git_commit_id("res://addons/penny_godot/"),
			&"git_rev_project": PennyUtils.get_git_commit_id(),
			&"screenshot": null,
			&"state": JSONSerialize.serialize(Cell.ROOT),
			&"history": host.history.export_json(),
			&"history_index": clampi(host.history_index, 0, host.history.records.size() - 1)
		})

	func _import_json(json: Dictionary) -> void:
		Cell.ROOT.import_cell(json[&"state"], host)

		host.history.import_json(json[&"history"].merged({ &"__host__": host }))
		host._history_index = json[&"history_index"]


func save() -> void:
	var path = await prompt_file_path(FileDialog.FILE_MODE_SAVE_FILE)
	if path == null: return

	var data := SaveData.new(self, path)
	data.save_to_file()


func load() -> void:
	var path = await prompt_file_path(FileDialog.FILE_MODE_OPEN_FILE)
	if path == null: return

	abort()

	var data := SaveData.new(self, path)
	data.load_from_file()

	while history_cursor and not history_cursor.stmt.is_loadable:
		_history_index -= 1

	execute_record(history_cursor)


func prompt_file_path(mode : FileDialog.FileMode) :
	var file_dialog := FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.file_mode = mode
	file_dialog.filters = [ "*.json", "*.dat" ]
	self.add_child(file_dialog)
	file_dialog.popup_centered_ratio(0.5)
	var result = await Async.any([file_dialog.file_selected, file_dialog.canceled])
	file_dialog.queue_free()
	return result

#endregion
