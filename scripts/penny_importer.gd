
## Persistent autoload node that watches for file changes and handles the Penny environment.
extends Node

static var REGEX := RegEx.new()
const PNY_FILE_EXPR = "(?i).+\\.pny"
const PNY_FILE_ROOT = "res://"
const PNY_FILE_OMIT = [
	".godot",
	".vscode",
	"addons",

	## Temporary
	"assets",
]

static var paths_dates : Dictionary

func _ready() -> void:
	REGEX.compile(PNY_FILE_EXPR)
	if !REGEX.is_valid():
		print("RegEx expression is not valid: \"" + PNY_FILE_EXPR + "\"")

	reload()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		# pass
		reload()

static func reload(hard: bool = false) -> void:
	print("***	RELOADING PENNY SCRIPTS")

	print("***		Detecting file changes...")

	var files : Array[FileAccess]
	if hard:
		files = open_all()
	else:
		files = open_modified()

	if files.size() == 0:
		print("***		No file changes detected.")
	else:
		print("***		Parsing ", files.size(), " updated file(s)...")

		var parsers = get_parsers(files)
		for i in parsers:
			i.parse_file()
		Penny.reload_labels()

	print("***	RELOADING COMPLETE\n")

static func open_modified() -> Array[FileAccess]:
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

static func open_all() -> Array[FileAccess]:
	var result : Array[FileAccess] = []

	paths_dates.clear()
	for i in get_all_paths():
		paths_dates[i] = FileAccess.get_modified_time(i)
		result.append(FileAccess.open(i, FileAccess.READ))
		# print("+ " + i)

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
