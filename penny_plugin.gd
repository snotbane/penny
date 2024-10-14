
## Handles debug tools for the editor only.
@tool
class_name PennyPlugin extends EditorPlugin

static var inst : PennyPlugin
static var prefab_dock: PackedScene = load("res://addons/penny_godot/editor/scenes/penny_dock.tscn")

var dock : Control
var importer : PennyImporter

func _enter_tree() -> void:
	inst = self

	dock = prefab_dock.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)

	# importer = PennyImporter.new()
	# dock.add_child.call_deferred(importer)


func _exit_tree() -> void:
	# remove_control_from_docks(dock)
	pass
