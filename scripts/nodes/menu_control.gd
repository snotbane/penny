
@tool
class_name PennyMenuControl extends PennyMenu_

@export var button_prefab : PackedScene = load("res://addons/penny_godot/scenes/menu_button_default.tscn")
@export var button_container : Container

func _populate(_host: PennyHost, _attach: Variant = null) -> void:
	super._populate(_host, _attach)

func _ready() -> void:
	if not attach: return
	var options : Array = attach.get_data(PennyObject.OPTIONS_KEY)
	for i in options:
		var option : PennyObject = i.evaluate(host)

		var button : PennyMenuButton = button_prefab.instantiate()
		button.pressed.connect(close)

		button.receive(str(option))

		button_container.add_child(button)
