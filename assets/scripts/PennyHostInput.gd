extends Node

var host : PennyHost :
	get:
		assert(get_parent() is PennyHost, "PennyInput must be the direct child of a PennyHost.")
		return get_parent()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(Penny.INPUT_ROLL_BACK):
		host.roll_back()
	elif event.is_action_pressed(Penny.INPUT_ROLL_AHEAD):
		host.roll_ahead()
