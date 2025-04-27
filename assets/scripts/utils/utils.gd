
@tool class_name PennyUtils

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
