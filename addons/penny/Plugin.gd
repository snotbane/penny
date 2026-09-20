@tool
extends EditorPlugin

const AUTOLOAD_NAME := "PennyAutoload"
const AUTOLOAD_SCRIPT := "res://addons/penny/script/Penny.gd"

const DEBUG_WINDOW_AUTOLOAD_NAME := "PennyDebugWindow"
const DEBUG_WINDOW_AUTOLOAD_SCRIPT := "res://addons/penny/scene/debug/PennyDebugWindow.gd"

static var IMPORT_PLUGIN := preload("res://addons/penny/script/PennyScriptImportPlugin.gd").new()

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


func _exit_tree() -> void:
	remove_import_plugin(IMPORT_PLUGIN)
