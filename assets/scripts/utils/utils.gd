
@tool
class_name Utils

const OMIT_FILE_SEARCH_DEFAULT := [
	".godot",
	".vscode",
	".templates",
	"addons"
]
const OMIT_FILE_SEARCH_INCLUDE_ADDONS := [
	".godot",
	".vscode",
	".templates",
]

static var valid_file_paths : Array[String] = get_paths_in_project("")

static func get_paths_in_project(ext: String, omit := OMIT_FILE_SEARCH_DEFAULT, start_path := "res://") -> Array[String]:
	var dir := DirAccess.open(start_path)
	if not dir: return []
	var result : Array[String]
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var next_path := start_path.path_join(file_name)
		if dir.current_is_dir():
			if not omit.has(file_name):
				result.append_array(get_paths_in_project(ext, omit, next_path))
		elif file_name.ends_with(ext):
			result.push_back(next_path)
		file_name = dir.get_next()
	return result


static func get_scripts_in_project(type: String, omit := OMIT_FILE_SEARCH_DEFAULT, start_path := "res://") -> Array[Script]:
	if not OS.is_debug_build():
		printerr("Attempting to access scripts directly in non-debug build. This is likely to cause issues unless GDScript Export Mode is set to Text (easier debugging). Whatever you are doing, use an alternative method for release.")

	var result : Array[Script]
	var paths := Utils.get_paths_in_project(".gd", omit, start_path)
	# print(paths)

	for path in paths:
		var script : Script = load(path)
		if Utils.script_extends_from(script, type):
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


static func is_valid_path(path: String) -> bool:
	if Engine.is_editor_hint(): valid_file_paths = get_paths_in_project("")
	return OS.has_feature("template") or valid_file_paths.has(path)


## Loads a resource, but first checks to see if it exists. Returns null if not. Doesn't throw any errors in editor.
static func safe_load(path: String) -> Resource:
	if OS.has_feature("template") or Utils.is_valid_path(path):
		return ResourceLoader.load(path, "", ResourceLoader.CacheMode.CACHE_MODE_REUSE)
	return null


static func array_to_string(arr: Array) -> String:
	var result := ""
	for i in arr.size():
		result += str(arr[i]) + ",\n"
	result = result.substr(0, result.length() - 2)
	return result


static func array_2d_to_string(arr: Array) -> String:
	var result := ""
	for y in arr.size():
		result += "["
		for x in arr[y].size():
			result += str(arr[y][x]) + ", "
		result = result.substr(0, result.length() - 2) + "],\n"
	result = result.substr(0, result.length() - 2)
	return result

static func node_children_to_string(node: Node, all_descendants := false, include_internal := false) -> String:
	return _node_children_to_string(node, all_descendants, include_internal, 0)
static func _node_children_to_string(node: Node, all_descendants := false, include_internal := false, depth := 0) -> String:
	var result := "\t".repeat(depth) + node.to_string() + "\n"
	for child in node.get_children():
		if all_descendants:
			result += _node_children_to_string(child, true, include_internal, depth + 1)
		else:
			result += "\t".repeat(depth + 1) + child.to_string() + "\n"
	return result


static func get_git_commit_id(dir: String = "res://") -> String:
	var args := ["rev-parse", "HEAD"]
	if not dir.is_empty():
		args.insert(0, "--git-dir=" + ProjectSettings.globalize_path(dir) + ".git")

	var output := []
	var response = OS.execute("git", args, output)
	if response == 0:  # Command executed successfully
		return output[0].strip_edges()  # Remove extra whitespace or newlines
	else:
		return "Unknown Commit"  # Fallback if Git isn't available or fails
