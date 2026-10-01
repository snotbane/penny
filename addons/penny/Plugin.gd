@tool
extends EditorPlugin

const AUTOLOAD_NAME := "PennyAutoload"
const AUTOLOAD_SCRIPT := "res://addons/penny/script/Penny.gd"

const DEBUG_WINDOW_AUTOLOAD_NAME := "PennyDebugWindow"
const DEBUG_WINDOW_AUTOLOAD_SCRIPT := "res://addons/penny/scene/debug/PennyDebugWindow.gd"

static var IMPORT_PLUGIN := preload("res://addons/penny/script/PennyScriptImportPlugin.gd").new()

## Adds a new input binding to the project settings.
static func add_default_input_binding(binding_name: String, events: Array = [], deadzone := 0.2) -> void:
	if not binding_name.begins_with("input/"):
		binding_name = "input/" + binding_name

	if ProjectSettings.get_setting(binding_name) != null: return

	ProjectSettings.set_setting(binding_name, {
		"deadzone": deadzone,
		"events": events,
	})


## Adds a new project setting. Call this in [member _enter_tree].
static func add_default_project_setting(setting_info: Dictionary, value: Variant) -> void:
	if not ProjectSettings.has_setting(setting_info.name):
		ProjectSettings.set_setting(setting_info.name, value)
		ProjectSettings.save()

	ProjectSettings.add_property_info(setting_info)
	ProjectSettings.set_initial_value(setting_info.name, value)


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)
	add_autoload_singleton(DEBUG_WINDOW_AUTOLOAD_NAME, DEBUG_WINDOW_AUTOLOAD_SCRIPT)

	ProjectSettings.save()


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_autoload_singleton(DEBUG_WINDOW_AUTOLOAD_NAME)

	ProjectSettings.save()


func _enter_tree() -> void:
	add_import_plugin(IMPORT_PLUGIN)

	add_default_project_setting({
			"name": "penny/typewriter/rate_base",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.0,200.0,1.0,or_greater",
		},
		100.0
	)


func _exit_tree() -> void:
	remove_import_plugin(IMPORT_PLUGIN)
