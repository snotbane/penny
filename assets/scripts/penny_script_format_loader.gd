@tool class_name PennyScriptFormatLoader extends ResourceFormatLoader

func _handles_type(type: StringName) -> bool:
	return type == &"Resource"

func _get_recognized_extensions() -> PackedStringArray:
	return Penny.RECOGNIZED_EXTENSIONS

func _get_resource_script_class(path: String) -> String:
	return "PennyScriptImporter"

func _get_resource_type(path: String) -> String:
	return "Resource"

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)

	assert(file != null, "Failed to load resource at path: '%s'" % path)
	print("path : %s" % [ path ])

	var result : PennyScript = null if Engine.is_editor_hint() else Penny.find_script_from_path(path)
	if result == null:
		result = PennyScript.new(path)

	result.update_from_file(file)
	Penny.reload_single(result)

	return result
