
class_name HistoryHandler extends Control

@export var vbox : VBoxContainer
@export var caret : Control

var _verbosity : int = 0
@export var verbosity : int = 0 :
	get: return _verbosity
	set (value):
		if _verbosity == value: return
		_verbosity = value

		if vbox == null: return
		for i in vbox.get_children():
			i.refresh_visibility(_verbosity)

@export var caret_index : int

var history : Array[Penny.Record]

func _ready() -> void:

	for i in vbox.get_children():
		i.queue_free()

func _process(_delta: float) -> void:

	if vbox.get_child_count() >= 2:
		caret.global_position = vbox.get_child(1).global_position

func record(stmt: Penny.Statement) -> void:

	var msg := Penny.Message.new(stmt)
	var rec := Penny.Record.new(stmt, msg.text)
	history.push_back(rec)

	var inst := HistoryRecordLabel.new(rec, verbosity)
	vbox.add_child(inst)
