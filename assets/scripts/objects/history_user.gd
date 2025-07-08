## Abstract base class for displaying some element(s) from the global Penny History.
class_name HistoryUser extends Node

var _history : History
var history : History :
	get: return _history
	set(value):
		if _history == value: return
		_history = value

var _history_index : int
var history_index : int :
	get: return _history_index
	set(value):
		value = clamp(value, -1, history.records.size() - 1)
		if _history_index == value: return
		_set_history_index(value)
func _set_history_index(value: int) -> void:
	_history_index = value
var history_cursor : Record :
	get:
		if history_index == -1: return null
		else: return history.records[history_index]


func _init() -> void:
	history = History.new()
