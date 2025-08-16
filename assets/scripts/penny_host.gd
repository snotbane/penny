
## Node that actualizes Penny statements. This stores local data_root and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.
class_name PennyHost extends HistoryUser

#region Save

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
			&"state": Cell.ROOT.export_json(),
			&"history": host.history.export_json(),
			&"history_index": clampi(host.history_index, 0, host.history.records.size() - 1)
		})

	func _import_json(json: Dictionary) -> void:
		host.history.import_json(json[&"history"].merged({ &"__host__": host }))
		host._history_index = json[&"history_index"]
		Cell.ROOT.import_json(json[&"state"])

#endregion

signal on_try_advance
signal on_data_modified
signal on_close
signal finished_execution

signal on_roll_back_disabled(value : bool)
signal on_roll_ahead_disabled(value : bool)

## If enabled, the host will begin execution on ready.
@export var autostart := false

## The label in Penny scripts to start at. Make sure this is populated with a valid label.
@export var start_label := &"start"

@export var allow_rolling := true

@export_subgroup("Debug")

@export var debug_log_stmts : bool

static var insts : Array[PennyHost] = []

var call_stack : Array[Stmt]

var cursor : Stmt

var last_valid_cursor : Stmt
var expecting_conditional : bool

var is_skipping : bool

## Returns the object in data that has most recently sent a message.
var last_dialog_object : Cell :
	get:
		var last_dialog := history.last_dialog
		if last_dialog: return last_dialog.stmt.subject_dialog_path.evaluate()
		return null

func _set_history_index(value: int) -> void:
	self.abort(Record.Response.IGNORE)

	var increment := signi(value - _history_index)
	while _history_index != value:
		if increment > 0 and history_cursor:
			history_cursor.undo()

		_history_index += increment

		if increment < 0 and history_cursor:
			history_cursor.redo()

	execute_at_history_cursor()


var can_roll_back : bool :
	get: return history.get_roll_back_point(history_index) != -1


var can_roll_ahead : bool :
	get: return history_index != -1


func _init() -> void:
	insts.push_back(self)

	super._init()


func _exit_tree() -> void:
	insts.erase(self)
	# Cell.ROOT.clear_instances(true)


func _ready() -> void:
	Penny.inst.on_reload_finish.connect(try_reload)

	if autostart:
		jump_to.call_deferred(start_label)

	history.record_added.connect(self.emit_roll_events.unbind(1))
	self.emit_roll_events()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() : return
	if event.is_action_pressed(&"penny_skip"):
		skip_to_next()
	elif event.is_action_pressed(&"penny_roll_back"):
		roll_back()
	elif event.is_action_pressed(&"penny_roll_ahead"):
		roll_ahead()


# func _physics_process(delta: float) -> void:
# 	if is_skipping:
# 		skip_process()


func try_reload(success: bool) -> void:
	if self.cursor:
		self.abort(Record.Response.IGNORE)
		reset_history_in_place()

	if self.last_valid_cursor:
		var start : Stmt = self.last_valid_cursor.owner.diff.remap_stmt_index(self.last_valid_cursor)
		if success:
			## TODO: Go back through the records till you find the new cursor, and undo stmts until that point.
			# self.last_valid_cursor.undo(history_cursor)
			self.last_valid_cursor = null
			self.execute(start)
		else:
			self.last_valid_cursor = null


func perform_inits() -> void:
	for init in Penny.inits:
		await self.execute(init)


func perform_inits_selective(scripts: Array[PennyScript]) -> void:
	for init in Penny.inits:
		if not scripts.has(init.owner): continue
		await self.execute(init)


func jump_to(label: StringName) -> void:
	self.abort(Record.Response.RECORD_ONLY)
	self.execute(Penny.get_stmt_from_label(label))


func call_to(label: StringName) -> void:
	self.call_stack.push_back(cursor.next_in_order)
	self.jump_to(label)


func execute(stmt : Stmt) :
	cursor = stmt
	if cursor == null: return
	last_valid_cursor = cursor

	if debug_log_stmts: print("%s %s" % [name, cursor._debug_string_do_not_use_for_anything_else_seriously_i_mean_it])

	var record : Record = cursor.pre_execute(self)

	if record.is_recorded:
		reset_history_in_place()
		history.add(record)

	await cursor.execute(record)

	cursor = null
	if record.is_recorded and record.is_advanced:
		cursor = self.next(record)
		last_valid_cursor = cursor
		execute(cursor)


func abort(response : Record.Response) -> void:
	if cursor == null: return
	cursor.abort(history.most_recent, response)


func skip_to_next() -> void:
	if cursor and not cursor.is_skippable: return

	if history_cursor != null:
		roll_ahead()
	else:
		abort(Record.Response.RECORD_AND_ADVANCE)


func next(record : Record) -> Stmt:
	var result : Stmt = record.next()
	if result == null:
		if call_stack:
			return call_stack.pop_back()
		else:
			on_reach_end()
	return result


func execute_at_history_cursor() :
	execute(history_cursor.stmt if history_cursor else history.most_recent.stmt)
	emit_roll_events()


func on_reach_end() -> void:
	close()


func close() -> void:
	on_close.emit()
	return


func roll_ahead() -> void:
	if not (allow_rolling and can_roll_ahead): return
	super.roll_ahead()


func roll_back() -> void:
	if not (allow_rolling and can_roll_back): return
	super.roll_back()


func emit_roll_events() -> void:
	on_roll_ahead_disabled.emit(not can_roll_ahead)
	on_roll_back_disabled.emit(not can_roll_back)


func save() -> void:
	var path = await prompt_file_path(FileDialog.FILE_MODE_SAVE_FILE)
	if path == null: return

	var data := SaveData.new(self, path)
	data.save_to_file()


func load() -> void:
	var path = await prompt_file_path(FileDialog.FILE_MODE_OPEN_FILE)
	if path == null: return

	abort(Record.Response.IGNORE)

	var data := SaveData.new(self, path)
	data.load_from_file()

	while history_cursor and not history_cursor.stmt.is_loadable:
		_history_index -= 1

	execute_at_history_cursor()


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
