
class_name PennyScriptResourceFormatLoader extends ResourceFormatLoader

const RECOGNIZED_TYPE := StringName('PennyScriptResource')

const RECOGNIZED_EXTENSIONS : PackedStringArray = [
	"txt",
	"pny",
]

func _handles_type(type: StringName) -> bool:
	return type == RECOGNIZED_TYPE

func _get_recognized_extensions() -> PackedStringArray:
	return RECOGNIZED_EXTENSIONS

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		return PennyScriptResource.new(hash(file.get_path()), file.get_as_text())
	else:
		printerr("Failed to load file at path: ", path)
		return null
