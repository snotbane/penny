
class_name HistoryHandler extends Control

var _shown : bool = false
@export var shown : bool :
	get: return _shown
	set (value) :
		if _shown == value: return
		_shown = value
		if _shown:
			animation_player.play('show')
		else:
			animation_player.play('hide')

@export var animation_player : AnimationPlayer
@export var vbox : VBoxContainer

var controls : Array[PennyMessageLabel]

func _ready() -> void:
	visible = shown

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_history'):
		shown = not shown

func receive(rec: Record) -> void:
	var control := PennyMessageLabel.new()
	control.populate(rec)
	controls.push_back(control)
	vbox.add_child(control)

func rewind_to(rec: Record) -> void:
	while controls.size() > rec.stamp:
		var control = controls.pop_back()
		vbox.remove_child(control)
		control.queue_free()
