@tool
class_name PennyScriptImportPlugin
extends EditorImportPlugin


# func _can_import_threaded() -> bool:
# 	return false


# func _get_build_dependencies(path: String) -> PackedStringArray:
# 	return []


# func _get_format_version() -> int:
# 	return 0


func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return []


# func _get_import_order() -> int:
# 	return 0


func _get_importer_name() -> String:
	return "penny.native.importer"


# func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
# 	return true


# func _get_preset_count() -> int:
# 	return 1


# func _get_priority() -> float:
# 	return 1.0


func _get_recognized_extensions() -> PackedStringArray:
	return [
		"pen",
		"penny"
	]


func _get_resource_type() -> String:
	return "Resource"


func _get_save_extension() -> String:
	return "res"


func _get_visible_name() -> String:
	return "Penny Script"


func _get_preset_name(preset_index: int) -> String:
	return "Default"


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	# print("_import")
	# print("source_file : %s" % [source_file])
	# print("save_path : %s" % [save_path])
	# print("options : %s" % [options])
	# print("platform_variants : %s" % [platform_variants])
	# print("gen_files : %s" % [gen_files])
	var file_access := FileAccess.open(source_file, FileAccess.READ)
	if not file_access:
		printerr(
			"Failed to load PennyScript at path :: '%s' :: %s (error %s)" % [
				source_file,
				error_string(FileAccess.get_open_error()),
				FileAccess.get_open_error(),
			]
		)
		return FileAccess.get_open_error()

	var target_path := "%s.%s" % [
		save_path,
		_get_save_extension(),
	]
	var target_script: PennyScript = load(target_path)

	var parser := PennyScript.PennyParser.new(file_access, target_script)
	var result := parser.process()

	if result:
		if result.errors:
			result.print_errors()
		else:
			result._ready()

	return ResourceSaver.save(result, target_path)
