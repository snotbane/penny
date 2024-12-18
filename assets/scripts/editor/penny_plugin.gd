
## Handles debug tools for the editor only.
@tool
class_name PennyPlugin extends EditorPlugin

const RECOGNIZED_EXTENSIONS : PackedStringArray = ["pny"]
const PENNY_DOCK_SCENE : PackedScene = preload("res://addons/penny_godot/assets/scenes/penny_dock.tscn")

static var inst : PennyPlugin

# Replace this value with a PascalCase autoload name, as per the GDScript style guide.
const AUTOLOAD_NAME = "PennyImporterAutoload"

var dock : Control


func _enter_tree() -> void:
	inst = self
	dock = PENNY_DOCK_SCENE.instantiate()
	self.add_control_to_bottom_panel(dock, "Penny")


func _exit_tree() -> void:
	self.remove_control_from_bottom_panel(dock)


func _enable_plugin():
	# The autoload can be a scene or script file.
	self.add_autoload_singleton(AUTOLOAD_NAME, "res://addons/penny_godot/scripts/nodes/penny_importer.gd")


func _disable_plugin():
	self.remove_autoload_singleton(AUTOLOAD_NAME)
