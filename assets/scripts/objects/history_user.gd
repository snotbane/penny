## Abstract base class for displaying some element(s) from the global Penny History.
class_name HistoryUser extends Node

signal record_added(record: Record)

var _history : History
var history : History :
	get: return _history
	set(value):
		if _history == value: return
		_history = value
		_history.record_added.connect(record_added.emit)

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
		if _history_index < 0 or _history_index >= history.records.size(): return null
		else: return history.records[history_index]


func _init() -> void:
	history = History.new()


func roll_ahead() -> void:
	history_index = history.get_roll_ahead_point(history_index)

func roll_back() -> void:
	history_index = history.get_roll_back_point(history_index)

func roll_end() -> void:
	history_index = history.records.size()

func reset_history_in_place() -> void:
	history.reset_at(history_index)
	_history_index = history.records.size()

func clear_history() -> void:
	history.records.clear()
	_history_index = 0
