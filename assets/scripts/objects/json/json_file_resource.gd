class_name JSONFileResource extends JSONResource

#region Statics

const SECONDS_IN_DAY := 86400
const SECONDS_IN_HOUR := 3600
const SECONDS_IN_MINUTE := 60

const K_TIME_CREATED := &"time_created"
const K_TIME_MODIFIED := &"time_modified"

static var NOW : int :
	get: return floori(Time.get_unix_time_from_system())

## Adapted from:	https://github.com/godotengine/godot-proposals/issues/5515#issuecomment-1409971613
static func get_local_datetime(unix_time: int) -> int:
	return unix_time + Time.get_time_zone_from_system().bias * SECONDS_IN_MINUTE

#endregion

signal modified

var path_ext : String :
	get: return _get_path_ext()
func _get_path_ext() -> String:
	return ".json"

var file_exists : bool :
	get: return FileAccess.file_exists(save_path)

@export var time_created : int
@export var time_modified : int

@export_storage var save_path : String
func generate_save_path(folder := "user://", name := str(randi())) -> String:
	var result := ""
	var _name := name
	while true:
		result = "%s%s%s" % [folder, _name, path_ext]
		if not FileAccess.file_exists(result): break
		_name = "%s_%s" % [name, str(randi())]
	return result


func _init(__save_path__: String = generate_save_path()) -> void:
	save_path = __save_path__
	time_created = NOW
	time_modified = time_created

	if FileAccess.file_exists(save_path):
		load_from_file()
	else:
		save_to_file()


func shell_open() -> void:
	if not file_exists: return
	OS.shell_open(ProjectSettings.globalize_path(save_path))


func shell_open_location() -> void:
	OS.shell_open(get_parent_folder())


func get_parent_folder(levels: int = 1, path: String = ProjectSettings.globalize_path(save_path)) -> String:
	if path.is_empty(): return String()
	if levels <= 0: return path
	return get_parent_folder(levels - 1, path.substr(0, path.rfind("/")))


func save_changes(path: String = save_path) -> void:
	time_modified = NOW
	save_to_file(path)
	modified.emit()


func save_to_file(path: String = save_path) -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		printerr("Cannot save to file, file does not exist: %s" % save_path)
		return
	file.store_string(_export_json_string())
func _export_json_string() -> String:
	return JSON.stringify(export_json())
func export_json() -> Dictionary:
	var result := {
		K_TIME_CREATED: time_created,
		K_TIME_MODIFIED: time_modified,
	}
	result.merge(super.export_json())
	return result


func load_from_file(path: String = save_path) -> void:
	save_path = path
	if not file_exists:
		push_error("Cannot load from file, file does not exist: %s" % save_path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_import_json_string(file.get_as_text())
func _import_json_string(text: String) -> void:
	var json = JSON.parse_string(text)
	if json == null:
		printerr("Couldn't parse string to json: %s" % text)
		return
	import_json(json)
func import_json(json: Dictionary) -> void:
	time_created = json[K_TIME_CREATED]
	time_modified = json[K_TIME_MODIFIED]
	super.import_json(json)
