
@tool
class_name Penny extends Node

const PNY_FILE_EXTENSION := ".pny"
const OMIT_SCRIPT_FOLDERS := [
	".godot",
	".vscode",
	".templates",
	"addons",
	"old",
	"temp",
	"tests",
]
static var SCRIPT_RESOURCE_LOADER := preload("res://addons/penny_godot/assets/scripts/penny_script_format_loader.gd").new()
static var PENNY_DEBUG_SCENE := preload("res://addons/penny_godot/assets/scenes/penny_debug.tscn")

static var inst : Penny
static var is_reloading_bulk : bool = false
static var is_all_scripts_valid : bool = true
static var script_reload_timestamps : Dictionary

static var scripts : Array[PennyScript]
static var inits : Array[Stmt]
static var labels : Dictionary

static var errors : Array[String] :
	get:
		var result : Array[String] = []
		for script in scripts:
			result.append_array(script.errors)
		return result

static var reload_cache_mode : ResourceLoader.CacheMode :
	get: return ResourceLoader.CacheMode.CACHE_MODE_REUSE if OS.has_feature("template") else ResourceLoader.CacheMode.CACHE_MODE_REPLACE


static func register_formats() -> void:
	ResourceLoader.add_resource_format_loader(SCRIPT_RESOURCE_LOADER)


static func find_script_from_path(path: String) -> PennyScript:
	for i in scripts:
		if i.resource_path == path:
			return i
	return null


static func get_stmt_from_address(path: String, index: int) -> Stmt:
	for script in scripts:
		if script.resource_path != path: continue
		return script.stmts[index]
	return null


static func get_stmt_from_label(label_name: StringName) -> Stmt:
	if labels.has(label_name):
		return labels[label_name]
	else:
		printerr("Label '%s' does not exist in any loaded script." % label_name)
		return null


static func load_script(path: String, type_hint := "") -> Variant:
	return ResourceLoader.load(path, type_hint, reload_cache_mode)


static func reload_all() -> void:
	is_reloading_bulk = true
	var result : Array[PennyScript] = []

	script_reload_timestamps.clear()
	for path in Utils.get_paths_in_project(PNY_FILE_EXTENSION, OMIT_SCRIPT_FOLDERS):
		script_reload_timestamps[path] = FileAccess.get_modified_time(path)
		result.push_back(Penny.load_script(path))

	Penny.reload_many(result)
	is_reloading_bulk = false


static func reload_updated() -> void:
	is_reloading_bulk = true
	var result : Array[PennyScript] = []

	var new_paths := Utils.get_paths_in_project(PNY_FILE_EXTENSION, OMIT_SCRIPT_FOLDERS)
	var del_paths : Array[String] = []
	for k in script_reload_timestamps.keys():
		del_paths.push_back(k)
	for path in new_paths:
		if script_reload_timestamps.has(path):
			del_paths.erase(path)
			if FileAccess.get_modified_time(path) != script_reload_timestamps[path]:
				result.push_back(Penny.load_script(path))
		else:
			result.push_back(Penny.load_script(path))
		script_reload_timestamps[path] = FileAccess.get_modified_time(path)
	for path in del_paths:
		script_reload_timestamps.erase(path)

	Penny.reload_many(result)
	is_reloading_bulk = false


static func reload_single(script : PennyScript) -> void:
	## Check this so that scripts loading independently will reload the environment, but scripts loading in bulk will not.
	if is_reloading_bulk: return
	Penny.reload_many([script])


static func reload_many(_scripts: Array[PennyScript] = scripts):
	inst.on_reload_start.emit()

	if _scripts.size() > 0:

		for script in _scripts:
			var i : int = -1
			for j in scripts.size():
				if scripts[j].id == script.id: i = j; break
			if i == -1: scripts.push_back(script)
			else: scripts[i] = script

		labels.clear()

		for script in scripts:
			for stmt in script.stmts:
				stmt.reload()

		is_all_scripts_valid = errors.is_empty()

		if is_all_scripts_valid:
			print("Successfully loaded all %s script(s), %s total." % [str(_scripts.size()), str(scripts.size())])
			# inits.sort_custom(stmt_init_sort)
		else:
			printerr("Failed to load one or more scripts:")
			for e in errors:
				printerr("\t" + e)


		inst.on_reload_finish.emit(is_all_scripts_valid)
	elif is_all_scripts_valid:
		inst.on_reload_cancel.emit()
	else:
		inst.on_reload_finish.emit(false)


signal on_reload_start
signal on_reload_finish(success: bool)
signal on_reload_cancel
signal on_root_cell_modified


func _enter_tree() -> void:
	inst = self
	Penny.register_formats()


func _ready():
	if OS.is_debug_build():
		var debug_canvas := CanvasLayer.new()
		debug_canvas.layer = 256
		self.add_child.call_deferred(debug_canvas)
		var debug : PennyDebugUI = PENNY_DEBUG_SCENE.instantiate()
		on_reload_start.connect(debug.on_reload_start.emit)
		on_reload_finish.connect(debug.on_reload_finish.emit)
		on_reload_cancel.connect(debug.on_reload_cancel.emit)
		debug_canvas.add_child.call_deferred(debug)

	Penny.reload_all.call_deferred()


func _notification(what: int) -> void:
	if not OS.has_feature("template"):
		if what == NOTIFICATION_APPLICATION_FOCUS_IN:
			if Engine.is_editor_hint():
				Penny.register_formats()
			else:
				Penny.reload_updated.call_deferred()


static func get_value_as_string(value: Variant) -> String:
	if value == null:
		return "NULL"
	elif value is Cell:
		return value.key_name
	elif value is String:
		return "`%s`" % value
	elif value is Color:
		return "#" + value.to_html()
	return str(value)
