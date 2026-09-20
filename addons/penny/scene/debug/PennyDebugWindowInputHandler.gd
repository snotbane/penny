extends Node

var window: Node

func _init() -> void:
	name = "PennyDebugWindowInputHandler"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if InputMap.has_action(&"penny_debug_window_toggle"):
		if event.is_action_pressed(&"penny_debug_window_toggle"):
			window.toggle_visibility()
			get_viewport().set_input_as_handled()
		return

	if event.is_echo() or not event.is_pressed(): return

	if event is InputEventKey:
		if event.keycode == KEY_D and event.shift_pressed:
			window.toggle_visibility()
			get_viewport().set_input_as_handled()
