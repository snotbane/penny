
## Handles debug tools for the editor only.
@tool
class_name PennyPlugin extends EditorPlugin

const RECOGNIZED_EXTENSIONS : PackedStringArray = ["pny"]
const IMPORTER := "res://addons/penny_godot/assets/scripts/penny.gd"
const AUTOLOAD_NAME = "penny"


func _enable_plugin():
	self.add_autoload_singleton(AUTOLOAD_NAME, IMPORTER)
	# EditorInterface.get_resource_filesystem().resources_reimported.connect(_resources_reimported)


func _disable_plugin():
	self.remove_autoload_singleton(AUTOLOAD_NAME)
	# EditorInterface.get_resource_filesystem().resources_reimported.disconnect(_resources_reimported)


func _resources_reimported(resources: PackedStringArray) -> void:
	for path in resources: for ext in RECOGNIZED_EXTENSIONS:
		if path.ends_with(ext): _penny_resource_reimported(path); break


func _penny_resource_reimported(path: String) -> void:
	ResourceLoader.load(path)
