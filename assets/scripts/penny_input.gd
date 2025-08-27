extends Node

var host : PennyHost :
	get:
		assert(get_parent() is PennyHost, "PennyInput must be the direct child of a PennyHost.")
		return get_parent()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() : return
	if event.is_action_pressed(&"penny_skip"):
		host.user_skip()
	elif event.is_action_pressed(&"penny_roll_back"):
		host.roll_back()
	elif event.is_action_pressed(&"penny_roll_ahead"):
		host.roll_ahead()
