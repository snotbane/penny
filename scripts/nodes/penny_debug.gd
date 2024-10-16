
class_name PennyDebug extends Control

var host : PennyHost

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	host = PennyHost.insts[0]

	if OS.is_debug_build():
		visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	# if not OS.is_debug_build(): return
	if event.is_action_pressed('penny_history'):
		if visible:
			visible = false
	if event.is_action_pressed('penny_debug'):
		visible = not visible
