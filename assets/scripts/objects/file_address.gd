
class_name FileAddress extends RefCounted

var path : String
var line : int
var col : int

var path_absolute : String :
	get: return ProjectSettings.globalize_path(path)


func _init(_path: String, _line: int = -1, _col: int = -1) -> void:
	path = _path
	line = _line
	col = _col


func _to_string() -> String:
	return "%s,%s,%s" % [path, line, col]


static func from_string(s: String) -> FileAddress:
	var args = s.split(',')
	return FileAddress.new(args[0], int(args[1]), int(args[2]))


var pretty_string : String:
	get: return "[url=%s]@%s, ln %s[/url]" % [self.to_string(), path, line]


func open() -> void:
	var args = []

	var editor = OS.get_environment("EDITOR") # Get the system's default editor
	if editor == "":
		# push_warning("Unable to determine default editor. Defaulting to vscode.")
		editor = "code"

	match editor:
		"godot":
			# EditorInterface.edit_resource(load('res://'))
			# EditorInterface.get_script_editor().goto_line(ln)
			return
		"code":
			args.append_array(["--goto", "%s:%d" % [path_absolute, line]])
		"devenv":
			args.append_array(["/edit", "%s,%d" % [path_absolute, line]])
		_:
			push_error("Unsupported editor '%s'." % editor)
			return

	var os_name = OS.get_name()
	match os_name:
		"Windows":
			args.insert(0, "/c")
			args.insert(1, editor)
			editor = "cmd"

	OS.execute(editor, args)
