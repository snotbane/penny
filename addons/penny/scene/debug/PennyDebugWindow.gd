extends Window

const DEFAULT_WINDOW_SIZE_RATIO := 0.75
const SCENE := preload("res://addons/penny/scene/debug/PennyDebugControl.tscn")

var control: Control

func _init() -> void:
	title = "Penny [ Debug ]"
	process_mode = Node.PROCESS_MODE_ALWAYS

	close_requested.connect(hide)

	control = SCENE.instantiate()
	add_child(control)


func _ready() -> void:
	var input_handler := Node.new()
	input_handler.set_script(preload("res://addons/penny/scene/debug/PennyDebugWindowInputHandler.gd"))
	input_handler.window = self
	add_sibling.call_deferred(input_handler)
	add_child.call_deferred(input_handler.duplicate(DUPLICATE_DEFAULT | DUPLICATE_INTERNAL_STATE))

	popup_centered_ratio(DEFAULT_WINDOW_SIZE_RATIO)
	hide()


func toggle_visibility() -> void:
	visible = not visible
