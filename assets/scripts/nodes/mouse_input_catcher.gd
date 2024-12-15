extends Control

signal on_click

var was_pressed : bool
var is_mouse_inside : bool

func _enter_tree() -> void:
	self.mouse_entered.connect(self.set.bind("is_mouse_inside", true))
	self.mouse_exited.connect(self.set.bind("is_mouse_inside", false))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			self.was_pressed = true
		elif event.is_released():
			if self.was_pressed and self.is_mouse_inside:
				self.on_click.emit()
			self.was_pressed = false
