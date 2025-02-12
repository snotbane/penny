
## Node that actualizes Penny statements. This stores local data_root and records based on what the player chooses to do. Most applications will simply use an autoloaded, global host. For more advanced uses, you can instantiate multiple of these simultaneously for concurrent or even network-replicated instances. The records/state can be saved.
class_name PennyHost extends Node

class History:

	signal record_added(record : Record)
	signal record_removed(record : Record)

	var records : Array[Record]
	var max_size : int = -1

	var most_recent : Record :
		get: return records.front()


	var last_dialog : Record :
		get:
			for record in records:
				if record.stmt is StmtDialog:
					return record
			return null


	func _init(_max_size : int = -1) -> void:
		max_size = _max_size


	func add(record: Record) -> void:
		if max_size >= 0:
			while records.size() >= max_size:
				record_removed.emit(records.pop_back())

		records.push_front(record)
		record_added.emit(record)


	func reset_at(index : int) -> void:
		index += 1
		for i in index:
			record_removed.emit(records.pop_front())


	func get_roll_back_point(from: int) -> int:
		while from < records.size() - 1:
			from += 1
			if records[from].stmt.is_rollable: return from
		return -1


	func get_roll_ahead_point(from: int) -> int:
		while from > 0:
			from -= 1
			if records[from].stmt.is_rollable: return from
		return -1


	func get_reverse_index(i: int) -> int:
		return records.size() - i - 1


	func save_data() -> Variant:
		var copy := records.duplicate()
		copy.reverse()
		return {
			"records": Save.any(copy)
		}


	func load_data(host: PennyHost, json: Dictionary) -> void:
		records.clear()
		for record in json["records"]:
			records.push_front(Record.new(host, Penny.get_stmt_from_address(record["stmt"]["script"], record["stmt"]["index"]), Load.any(record["data"]), Record.Response.IGNORE))

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


var history : History
var _history_cursor_index : int = -1
var history_cursor_index : int = -1 :
	get: return _history_cursor_index
	set(value):
		value = clamp(value, -1, history.records.size() - 1)
		if _history_cursor_index == value: return

		self.abort(Record.Response.IGNORE)

		var increment := signi(value - _history_cursor_index)
		while _history_cursor_index != value:
			if increment > 0 and history_cursor:
				history_cursor.undo()

			_history_cursor_index += increment

			if increment < 0 and history_cursor:
				history_cursor.redo()

		self.execute_at_history_cursor()
		self.emit_roll_events()


var history_cursor : Record :
	get:
		if history_cursor_index == -1: return null
		return history.records[history_cursor_index]


var can_roll_back : bool :
	get: return history.get_roll_back_point(history_cursor_index) != -1


var can_roll_ahead : bool :
	get: return history_cursor_index != -1


func _init() -> void:
	insts.push_back(self)

	history = History.new()


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
	if event.is_action_pressed("penny_skip"):
		self.skip_to_next()
	elif event.is_action_pressed("penny_roll_back"):
		roll_back()
	elif event.is_action_pressed("penny_roll_ahead"):
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


func execute(stmt : Stmt) :
	cursor = stmt
	if cursor == null: return
	last_valid_cursor = cursor

	var record : Record = await cursor.execute(self)
	if record.is_recorded:
		reset_history_in_place()
		history.add(record)

		if record.is_advanced:
			cursor = self.next(record)
			last_valid_cursor = cursor
			self.execute(cursor)
		else:
			cursor = null
	else:
		cursor = null


func abort(response : Record.Response) -> void:
	if cursor == null: return
	cursor.abort(self, response)


func skip_to_next() -> void:
	if history_cursor != null:
		self.roll_ahead()
	else:
		self.abort(Record.Response.RECORD_AND_ADVANCE)


func roll_ahead() -> void:
	if not allow_rolling or not can_roll_ahead: return

	history_cursor_index = history.get_roll_ahead_point(history_cursor_index)


func roll_back() -> void:
	if not allow_rolling or not can_roll_back: return

	history_cursor_index = history.get_roll_back_point(history_cursor_index)


func roll_end() -> void:
	history_cursor_index = -1


func reset_history_in_place() -> void:
	history.reset_at(history_cursor_index)
	_history_cursor_index = -1


func clear_history() -> void:
	history.records.clear()
	_history_cursor_index = -1


func next(record : Record) -> Stmt:
	var result : Stmt = record.next()
	if result == null:
		if call_stack:
			return call_stack.pop_back()
		else:
			on_reach_end()
	return result


func execute_at_end() :
	await self.execute(self.next(history.most_recent))


func execute_at_history_cursor() :
	if history_cursor:
		self.execute(history_cursor.stmt)
	else:
		self.execute_at_end()


func on_reach_end() -> void:
	close()


func close() -> void:
	on_close.emit()
	return


func save() -> void:
	var path = await prompt_file_path(FileDialog.FILE_MODE_SAVE_FILE)
	if path == null: return

	var save_file := FileAccess.open(path, FileAccess.WRITE)
	var save_dict : Dictionary = save_data()
	var save_json := JSON.stringify(save_dict, "")
	save_file.store_line(save_json)

	print("Saved data to ", save_file.get_path_absolute())


func load() -> void:
	var path = await prompt_file_path(FileDialog.FILE_MODE_OPEN_FILE)
	if path == null : return

	var load_file := FileAccess.open(path, FileAccess.READ)
	var load_data = JSON.parse_string(load_file.get_as_text())
	assert(load_data != null, "JSON parser error; data couldn't be loaded.")

	Cell.ROOT.load_data(self, load_data["data"])

	history.load_data(self, load_data["history"])
	_history_cursor_index = history.get_reverse_index(load_data["history_cursor_index"])

	self.abort(Record.Response.IGNORE)
	self.execute_at_history_cursor()
	self.emit_roll_events()


func prompt_file_path(mode : FileDialog.FileMode) :
	var file_dialog := FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.file_mode = mode
	file_dialog.filters = [ "*.json" ]
	self.add_child(file_dialog)
	file_dialog.popup_centered_ratio(0.5)
	var result = await Async.any([file_dialog.file_selected, file_dialog.canceled])
	file_dialog.queue_free()
	return result


func save_data() -> Variant:
	return {
		"meta": {
			"git_rev_penny": Utils.get_git_commit_id("res://addons/penny_godot/"),
			"git_rev_project": Utils.get_git_commit_id(),
			"screenshot": null,
			"time_saved_utc": Time.get_datetime_dict_from_system(true),
		},
		"data": Save.any(Cell.ROOT),
		"history": Save.any(history),
		"history_cursor_index": history.get_reverse_index(history_cursor_index),
	}


func emit_roll_events() -> void:
	on_roll_ahead_disabled.emit(not can_roll_ahead)
	on_roll_back_disabled.emit(not can_roll_back)
