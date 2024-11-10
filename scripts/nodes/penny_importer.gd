
## Persistent autoload node that watches for file changes and handles the Penny environment.
@tool
class_name PennyImporter extends Node

static var SCRIPT_RESOURCE_LOADER = preload("res://addons/penny_godot/scripts/resource/penny_script_format_loader.gd").new()
static var DEBUG_SCENE : PackedScene = preload("res://addons/penny_godot/scenes/penny_debug.tscn")

static var inst : PennyImporter
static var REGEX : RegEx = RegEx.new()
const PENNY_FILE_EXT = ".pny"
const PNY_FILE_EXPR = "(?i).+\\.pny"
const PNY_FILE_ROOT = "res://"
const PNY_FILE_OMIT = [
	".godot",
	".vscode",
	"addons",

	## Temporary
	# "assets",
	"ignore",
]

signal on_reloaded

var paths_dates : Dictionary
var paths_dates2 : Dictionary

func _enter_tree() -> void:
	register_formats()


func _ready() -> void:
	inst = self
	REGEX = RegEx.new()
	REGEX.compile(PNY_FILE_EXPR)
	if !REGEX.is_valid():
		print("RegEx expression is not valid: \"" + PNY_FILE_EXPR + "\"")

	var debug_canvas := CanvasLayer.new()
	debug_canvas.layer = 256
	self.add_child.call_deferred(debug_canvas)
	var debug := DEBUG_SCENE.instantiate()
	debug_canvas.add_child.call_deferred(debug)


	reload.call_deferred()



func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		# if OS.is_debug_build():
		if Engine.is_editor_hint():
			register_formats()
		# pass
		# reload.call_deferred()

static func register_formats() -> void:
	ResourceLoader.add_resource_format_loader(SCRIPT_RESOURCE_LOADER)


func reload(hard: bool = false) -> void:
	var scripts : Array[PennyScript]
	var files : Array[FileAccess]
	if hard:
		scripts = load_all_script_resources()
		files = open_all()
	else:
		scripts = load_modified_script_resources()
		files = open_modified()

	if files.size() > 0:
		Penny.log_clear()
		Penny.valid = true

		Penny.import_scripts(scripts)
		var exceptions = Penny.validate()

		if exceptions:
			Penny.log_timed("Failed to load one or more scripts:", Penny.ERROR_COLOR)
			for i in exceptions:
				i.push()
			Penny.valid = false
		else:
			Penny.load()
			Penny.log_timed("Successfully loaded all (%s) scripts." % str(scripts.size()), Penny.HAPPY_COLOR)

		Penny.log_info()

		on_reloaded.emit()

		# print("***	RELOADING COMPLETE\n")

func open_modified() -> Array[FileAccess]:
	var result : Array[FileAccess] = []

	var new_paths = get_all_paths()

	var del_paths : Array[StringName] = []
	for i in paths_dates.keys():
		del_paths.append(i)

	for i in new_paths:
		if paths_dates.has(i):
			del_paths.erase(i)
			if FileAccess.get_modified_time(i) != paths_dates[i]:
				result.append(FileAccess.open(i, FileAccess.READ))
				# print("* " + i)
		else:
			result.append(FileAccess.open(i, FileAccess.READ))
			# print("+ " + i)
	for i in del_paths:
		paths_dates.erase(i)
		# print("- " + i)

	for i in new_paths:
		paths_dates[i] = FileAccess.get_modified_time(i)

	return result

func open_all() -> Array[FileAccess]:
	var result : Array[FileAccess] = []

	paths_dates.clear()
	for i in get_all_paths():
		paths_dates[i] = FileAccess.get_modified_time(i)
		result.append(FileAccess.open(i, FileAccess.READ))


	return result

func load_modified_script_resources() -> Array[PennyScript]:
	var result : Array[PennyScript] = []
	var new_paths := get_all_paths()
	var del_paths : Array[String] = []
	for k in paths_dates2.keys():
		del_paths.push_back(k)
	for path in new_paths:
		if paths_dates2.has(path):
			del_paths.erase(path)
			if FileAccess.get_modified_time(path) != paths_dates2[path]:
				print("Loading: ", path)
				result.push_back(load(path))
				print("Loaded: ", path)
		else:
			result.push_back(load(path))
		paths_dates2[path] = FileAccess.get_modified_time(path)
	for path in del_paths:
		paths_dates2.erase(path)
	return result

func load_all_script_resources() -> Array[PennyScript]:
	var result : Array[PennyScript] = []

	paths_dates2.clear()
	for path in get_all_paths():
		paths_dates2[path] = FileAccess.get_modified_time(path)
		print("Loading: ", path)
		result.push_back(load(path))
		print("Loaded: ", path)
	return result


static func get_all_paths(path: String = PNY_FILE_ROOT) -> Array[String]:
	return Utils.get_paths_in_project(PENNY_FILE_EXT, PNY_FILE_OMIT)
