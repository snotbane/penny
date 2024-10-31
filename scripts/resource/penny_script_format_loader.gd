
@tool
extends ResourceFormatLoader

const RECOGNIZED_TYPE := StringName('PennyScript')
const RECOGNIZED_EXTENSIONS : PackedStringArray = ["pny"]

func _handles_type(type: StringName) -> bool:
	return type == "Resource"

func _get_recognized_extensions() -> PackedStringArray:
	return RECOGNIZED_EXTENSIONS

func _get_resource_script_class(path: String) -> String:
	return "PennyScript"

func _get_resource_type(path: String) -> String:
	return "Resource"

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var result := PennyScript.new()
		result.update_from_file(file)
		return result
	else:
		printerr("Failed to load file at path: ", path)
		return null
