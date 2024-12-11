
## Persistent autoload node that watches for file changes and handles the Penny environment.
@tool
class_name PennyImporter extends Node

signal on_reload_start
signal on_reload_finish(success: bool)
signal on_reload_cancel


static var SCRIPT_RESOURCE_LOADER = preload("res://addons/penny_godot/scripts/resource/penny_script_format_loader.gd").new()
static var DEBUG_SCENE : PackedScene = preload("res://addons/penny_godot/assets/scenes/penny_debug.tscn")

static var inst : PennyImporter
static var REGEX : RegEx = RegEx.new()
const PENNY_FILE_EXT = ".pny"
const PNY_FILE_EXPR = "(?i).+\\.pny"
const PNY_FILE_ROOT = "res://"
const PENNY_FILE_OMIT = [
	".godot",
	".vscode",
	# "addons",

	## Temporary
	# "assets",
	"ignore",
]

static var reload_cache_mode : ResourceLoader.CacheMode :
	get:
		if OS.has_feature("template"):
			return ResourceLoader.CacheMode.CACHE_MODE_REUSE
		else:
			return ResourceLoader.CacheMode.CACHE_MODE_REPLACE


var paths_dates : Dictionary

var init_host : PennyHost


func _enter_tree() -> void:
	register_formats()


func _ready() -> void:
	inst = self
	REGEX = RegEx.new()
	REGEX.compile(PNY_FILE_EXPR)
	if !REGEX.is_valid():
		print("RegEx expression is not valid: \"" + PNY_FILE_EXPR + "\"")

	init_host = PennyHost.new()
	init_host.name = "importer_init_host"
	init_host.allow_rolling = false
	self.add_child.call_deferred(init_host)

	if not (OS.has_feature("template") or Engine.is_editor_hint()):
		var debug_canvas := CanvasLayer.new()
		debug_canvas.layer = 256
		self.add_child.call_deferred(debug_canvas)
		var debug : PennyDebug = DEBUG_SCENE.instantiate()
		on_reload_start.connect(debug.on_reload_start.emit)
		on_reload_finish.connect(debug.on_reload_finish.emit)
		on_reload_cancel.connect(debug.on_reload_cancel.emit)

		debug_canvas.add_child.call_deferred(debug)

	reload.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if Engine.is_editor_hint():
			register_formats()
		else:
			reload.call_deferred()

static func register_formats() -> void:
	ResourceLoader.add_resource_format_loader(SCRIPT_RESOURCE_LOADER)


func reload(hard: bool = false) -> void:
	# print("Reload (engine %s)" % Engine.is_editor_hint())
	# print("Deco master registry: ", Deco.MASTER_REGISTRY.keys())

	on_reload_start.emit()

	var scripts : Array[PennyScript]
	if hard:
		scripts = self.load_all_script_resources()
	else:
		scripts = self.load_modified_script_resources()

	if scripts.size() > 0:
		Penny.log_clear()
		Penny.valid = true

		Penny.import_scripts(scripts)
		var exceptions = Penny.refresh()

		if exceptions:
			Penny.log_timed("Failed to load one or more scripts:", Penny.ERROR_COLOR)
			for i in exceptions:
				i.push_error()
			Penny.valid = false
		else:
			Penny.load()
			Penny.log_timed("Successfully loaded all (%s) scripts." % str(scripts.size()), Penny.HAPPY_COLOR)
			init_host.perform_inits()
		Penny.log_info()

		on_reload_finish.emit(Penny.valid)
	elif Penny.valid:
		on_reload_cancel.emit()
	else:
		on_reload_finish.emit(false)


func load_modified_script_resources() -> Array[PennyScript]:
	var result : Array[PennyScript] = []
	var new_paths := get_all_paths()
	var del_paths : Array[String] = []
	for k in paths_dates.keys():
		del_paths.push_back(k)
	for path in new_paths:
		if paths_dates.has(path):
			del_paths.erase(path)
			if FileAccess.get_modified_time(path) != paths_dates[path]:
				result.push_back(ResourceLoader.load(path, "", reload_cache_mode))
		else:
			result.push_back(load(path))
		paths_dates[path] = FileAccess.get_modified_time(path)
	for path in del_paths:
		paths_dates.erase(path)
	return result

func load_all_script_resources() -> Array[PennyScript]:
	var result : Array[PennyScript] = []

	paths_dates.clear()
	for path in get_all_paths():
		paths_dates[path] = FileAccess.get_modified_time(path)
		result.push_back(ResourceLoader.load(path, "", reload_cache_mode))
	return result


static func get_all_paths(path: String = PNY_FILE_ROOT) -> Array[String]:
	return Utils.get_paths_in_project(PENNY_FILE_EXT, PENNY_FILE_OMIT)
