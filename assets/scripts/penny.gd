
@tool
class_name Penny extends Node

const OMIT_SCRIPT_FOLDERS := [
	".godot",
	".vscode",
	".templates",
	"addons"
]

static var inst : Penny
static var is_reloading_bulk : bool = false
static var is_all_scripts_valid : bool = true
static var script_reload_timestamps : Dictionary

static var scripts : Array[PennyScript]
static var labels : Dictionary

static var errors : Array[String] :
	get:
		var result : Array[String] = []
		for script in scripts:
			result.append_array(script.errors)
		return result

static var reload_cache_mode : ResourceLoader.CacheMode :
	get: return ResourceLoader.CacheMode.CACHE_MODE_REUSE if OS.has_feature("template") else ResourceLoader.CacheMode.CACHE_MODE_REPLACE


static func find_script_from_path(path: String) -> PennyScript:
	for i in scripts:
		if i.resource_path == path:
			return i
	return null


static func load(path: String, type_hint := "") -> Variant:
	return ResourceLoader.load(path, type_hint, reload_cache_mode)


static func reload_all() -> void:
	is_reloading_bulk = true
	var result : Array[PennyScript] = []

	script_reload_timestamps.clear()
	for path in Penny.get_script_paths():
		script_reload_timestamps[path] = FileAccess.get_modified_time(path)
		result.push_back(Penny.load(path))
	
	Penny.reload_many(result)
	is_reloading_bulk = false


static func reload_updated() -> void:
	is_reloading_bulk = true
	var result : Array[PennyScript] = []

	var new_paths := get_script_paths()
	var del_paths : Array[String] = []
	for k in script_reload_timestamps.keys():
		del_paths.push_back(k)
	for path in new_paths:
		if script_reload_timestamps.has(path):
			del_paths.erase(path)
			if FileAccess.get_modified_time(path) != script_reload_timestamps[path]:
				result.push_back(Penny.load(path))
		else:
			result.push_back(Penny.load(path))
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
	is_reloading_bulk = false


static func get_script_paths(omit := OMIT_SCRIPT_FOLDERS, start_path := "res://") -> PackedStringArray:
	var ext := ".pny"
	var dir := DirAccess.open(start_path)
	if not dir: return []
	var result : Array[String]
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var next_path := start_path + file_name
		if dir.current_is_dir():
			if not omit.has(file_name):
				result.append_array(Penny.get_script_paths(omit, next_path + "/"))
		elif file_name.ends_with(ext):
			result.push_back(next_path)
		file_name = dir.get_next()
	return result


static func register_formats() -> void:
	ResourceLoader.add_resource_format_loader(preload("res://addons/penny_godot/assets/scripts/penny_script_format_loader.gd").new())


signal on_reload_start
signal on_reload_finish(success: bool)
signal on_reload_cancel


func _enter_tree() -> void:
	inst = self
	Penny.register_formats()


func _ready():
	Penny.reload_all.call_deferred()


func _notification(what: int) -> void:
	if not OS.has_feature("template"):
		if what == NOTIFICATION_APPLICATION_FOCUS_IN:
			if Engine.is_editor_hint():
				Penny.register_formats()
			else:
				Penny.reload_updated.call_deferred()
