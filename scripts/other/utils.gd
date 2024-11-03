
class_name Utils

const DEFAULT_OMIT_FILE_SEARCH := [
	".godot",
	".vscode",
	".templates",
	"addons"
]

static func get_paths_in_project(ext: String, omit := DEFAULT_OMIT_FILE_SEARCH, start_path := "res://") -> Array[String]:
	var dir := DirAccess.open(start_path)
	if not dir: return []
	var result : Array[String]
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var next_path := start_path + file_name
		if dir.current_is_dir():
			if not omit.has(file_name):
				result.append_array(get_paths_in_project(ext, omit, next_path + "/"))
		elif file_name.ends_with(ext):
			result.push_back(next_path)
		file_name = dir.get_next()
	return result


static func get_scripts_in_project(type: String, omit := DEFAULT_OMIT_FILE_SEARCH, start_path := "res://") -> Array[Script]:
	var result : Array[Script]
	var paths := Utils.get_paths_in_project(".gd", omit, start_path)

	for path in paths:
		var script : Script = load(path)
		if Utils.script_extends_from(script, type):
			print(path)
			result.push_back(script)
	return result


static func script_extends_from(script: Script, type: String) -> bool:
	if not script: return false
	if script.get_instance_base_type() == type:
		return true
	var base = script.get_base_script()
	if not base: return false
	if base.get_global_name() == type:
		return true
	else:
		return script_extends_from(base, type)
