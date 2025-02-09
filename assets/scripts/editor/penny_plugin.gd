
## Handles debug tools for the editor only.
@tool
class_name PennyPlugin extends EditorPlugin

const RECOGNIZED_EXTENSIONS : PackedStringArray = ["pny"]
const IMPORTER := "res://addons/penny_godot/assets/scripts/penny.gd"
const AUTOLOAD_NAME = "penny"


func _enable_plugin():
	self.add_autoload_singleton(AUTOLOAD_NAME, IMPORTER)


func _disable_plugin():
	self.remove_autoload_singleton(AUTOLOAD_NAME)
