
class_name PennyDebugUI extends Control

static var inst : PennyDebugUI

signal on_host_changed(host: PennyHost)
signal on_reload_start
signal on_reload_finish(success: bool)
signal on_reload_cancel


func _ready() -> void:
	inst = self
	$overlay.visible = false


func _input(event: InputEvent) -> void:
	# if not OS.is_debug_build(): return
	if event.is_action_pressed("penny_debug"):
		$overlay.visible = not $overlay.visible