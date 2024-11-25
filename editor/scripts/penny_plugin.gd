
## Handles debug tools for the editor only.
@tool
class_name PennyPlugin extends EditorPlugin

const RECOGNIZED_EXTENSIONS : PackedStringArray = ["pny"]

static var inst : PennyPlugin
static var prefab_dock: PackedScene = load("res://addons/penny_godot/scenes/penny_dock.tscn")

# Replace this value with a PascalCase autoload name, as per the GDScript style guide.
const AUTOLOAD_NAME = "PennyImporterAutoload"

var dock : Control
# var importer : PennyImporter

func _enter_tree() -> void:
	inst = self

	dock = prefab_dock.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)

	# importer = PennyImporter.new()
	# dock.add_child.call_deferred(importer)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		remove_control_from_docks(dock)


func _enable_plugin():
	# The autoload can be a scene or script file.
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/penny_godot/scripts/nodes/penny_importer.gd")


func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)
