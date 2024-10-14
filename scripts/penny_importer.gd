
## Persistent autoload node that watches for file changes and handles the Penny environment.
@tool
class_name PennyImporter extends Node

static var inst : PennyImporter
static var REGEX : RegEx = RegEx.new()
const PNY_FILE_EXPR = "(?i).+\\.pny"
const PNY_FILE_ROOT = "res://"
const PNY_FILE_OMIT = [
	".godot",
	".vscode",
	"addons",

	## Temporary
	"assets",
]

var paths_dates : Dictionary

func _ready() -> void:
	inst = self
	REGEX = RegEx.new()
	REGEX.compile(PNY_FILE_EXPR)
	if !REGEX.is_valid():
		print("RegEx expression is not valid: \"" + PNY_FILE_EXPR + "\"")

	reload.call_deferred()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		# pass
		reload()

func reload(hard: bool = false) -> void:

	var files : Array[FileAccess]
	if hard:
		files = open_all()
	else:
		files = open_modified()

	if files.size() > 0:
		var host_application_string : String
		if Engine.is_editor_hint():
			host_application_string = "engine"
		else:
			host_application_string = "game"

		# print("***	RELOADING %s PENNY SCRIPTS ( %s )" % [files.size(), host_application_string])

		Penny.valid = true

		var parsers = get_parsers(files)
		var exceptions : Array[PennyException] = []
		for i in parsers:
			Penny.clear(i.file.get_path())
			exceptions.append_array(i.parse_file())

		Penny.log_clear()
		if exceptions.is_empty():
			Penny.load()
			if Penny.valid:
				Penny.log_timed("Successfully loaded all scripts.", Penny.HAPPY_COLOR)
		else:
			Penny.log_timed("Failed to load one or more scripts:", Penny.ERROR_COLOR)
			for i in exceptions:
				i.push()
			Penny.valid = false
		Penny.log_info()

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

static func get_parsers(files: Array[FileAccess]) -> Array[PennyParser]:
	var result : Array[PennyParser]
	for i in files:
		result.append(PennyParser.from_file(i))
	return result

static func get_all_paths(path: StringName = PNY_FILE_ROOT) -> Array[StringName]:
	var result : Array[StringName] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if ! PNY_FILE_OMIT.has(file_name):
					result.append_array(get_all_paths(path + file_name + "/"))
			else:
				if REGEX.search(file_name):
					result.append(path + file_name)
			file_name = dir.get_next()
	else:
		#print("An error occurred when trying to access the path \"" + path + "\"")
		pass

	return result
