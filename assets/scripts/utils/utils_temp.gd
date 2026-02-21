
@tool class_name PennyUtils

static var NOW : int :
	get: return floori(Time.get_unix_time_from_system())

static func get_paths_in_folder(root := "res://", include := RegEx.create_from_string(".*")) -> PackedStringArray:
	var dir := DirAccess.open(root)
	if not dir: return []

	var result : PackedStringArray = []
	dir.list_dir_begin()
	var file : String = dir.get_next()
	while file:
		var next := root.path_join(file)
		if dir.current_is_dir():
			result.append_array(get_paths_in_folder(next, include))
		elif include.search(file):
			result.push_back(next)
		file = dir.get_next()
	return result


static func get_git_commit_id(dir: String = "res://") -> String:
	var args := ["rev-parse", "HEAD"]
	if not dir.is_empty():
		args.insert(0, "--git-dir=" + ProjectSettings.globalize_path(dir) + ".git")

	var output := []
	var code = OS.execute("git", args, output)
	return output[0].strip_edges() if code == OK else "Unknown Commit!"


static func get_tab_string(string: String, minimum_length := 0, tab_size := 4) -> String:
	return "\t".repeat(floori((minimum_length - string.length()) / tab_size) + 1)

static func print_vars(dict: Dictionary) -> void:
	var longest_string_length := 0
	for k in dict.keys(): longest_string_length = maxi(longest_string_length, k.length())
	var string := ""
	for k in dict.keys(): string += "\t%s:%s%s" % [str(k), get_tab_string(str(k), longest_string_length), str(dict[k])]
	print("{\n%s\n}" % string)


static func print_vars_context(context: Object, vars: PackedStringArray = []) -> void:
	var dict : Dictionary = {}
	for v in vars: dict[v] = context.get(v)
	print_vars(dict)
