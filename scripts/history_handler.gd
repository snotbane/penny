
class_name HistoryHandler extends Control

@export var vbox : VBoxContainer

var _verbosity : int = 0
@export var verbosity : int = 0 :
	get: return _verbosity
	set (value):
		if _verbosity == value: return
		_verbosity = value

		if vbox == null: return
		for i in vbox.get_children():
			i.refresh_visibility(_verbosity)

var _caret_index : int = -1
var caret_index : int = -1 :
	get: return _caret_index
	set (value):
		if vbox.get_child_count() == 0: _caret_index = -1
		value = clamp(value, 0, vbox.get_child_count() - 1)
		if _caret_index == value: return
		_caret_index = value

var caret_node : Control :
	get: return vbox.get_child(_caret_index)

var caret_record : Penny.Record :
	get: return get_record(caret_index)

var caret_halting_index : int = 0 :
	get:
		var idx := -1
		for i in caret_index + 1:
			if get_record(i).statement.is_halting:
				idx += 1
		return idx
	set (value):
		if caret_halting_index == value: return
		for i in vbox.get_child_count():
			if get_record(i).statement.is_halting:
				if value == 0:
					caret_index = i
					return
				else:
					value -= 1

func _ready() -> void:
	pass
	# for i in vbox.get_children():
	# 	i.queue_free()

func record(rec: Penny.Record) -> void:
	var inst := PennyMessageLabel.new(self, rec, verbosity)
	vbox.add_child(inst)

func get_record(idx: int) -> Penny.Record:
	return vbox.get_child(idx).record

func focus_caret() -> void:
	if caret_node != null:
		caret_node.grab_focus()
		print("Set focus to %s" % caret_node)


func rewind_to(rec: Penny.Record) -> void:
	pass

func resize_records(length: int) -> void:
	while vbox.get_child_count() > length:
		var child = vbox.get_child(vbox.get_child_count() - 1)
		vbox.remove_child(child)
		child.queue_free()
