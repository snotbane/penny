
extends PennyPrompt

@export_file var button_scene_path : String = "res://addons/penny_godot/assets/scenes/prompt_button_default.tscn"
@export var button_container : Container

func _receive_options(_host: PennyHost, _options: Array) -> void:
	# var button_scene = load(button_scene_path)
	for path in _options:
		var option : Cell = path.evaluate()
		var button : PennyPromptButton = option.instantiate(host)
		button.pressed.connect(receive_response.bind(path))
		button_container.add_child(button)
