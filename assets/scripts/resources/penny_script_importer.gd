
## Persistent autoload node that watches for file changes and handles the Penny environment.
@tool
class_name PennyScriptImporter extends Node


func _enter_tree() -> void:
	register_formats()


# func _notification(what: int) -> void:
# 	if not OS.has_feature("template"):
# 		if what == NOTIFICATION_APPLICATION_FOCUS_IN:
# 			if Engine.is_editor_hint():
# 				register_formats()
# 			# else:
# 			# 	reload.call_deferred()


static func register_formats() -> void:
	ResourceLoader.add_resource_format_loader(preload("res://addons/penny_godot/assets/scripts/resources/penny_script_format_loader.gd").new())