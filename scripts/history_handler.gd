
class_name HistoryHandler extends Control

@export var vbox : VBoxContainer

var controls : Array[PennyMessageLabel]

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
