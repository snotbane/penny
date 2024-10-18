
@tool
class_name PennyMenuControl extends PennyMenu_

@export var button_prefab : PackedScene = load("res://addons/penny_godot/scenes/menu_button_default.tscn")
@export var button_container : Container

func _receive(options: Array) -> void:
	for i in options:
		var button : PennyMenuButton = button_prefab.instantiate()
		button.pressed.connect(close)

		button.receive(i)

		button_container.add_child(button)
