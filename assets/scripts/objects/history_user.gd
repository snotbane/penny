## Abstract base class for displaying some element(s) from the global Penny History.
class_name HistoryUser extends Node

signal record_added(record: Record)
signal on_roll_back_disabled(value : bool)
signal on_roll_ahead_disabled(value : bool)

var _history : History
var history : History :
	get: return _history
	set(value):
		if _history == value: return
		_history = value
		_history.record_added.connect(record_added.emit)

var _history_index : int = -1
var history_index : int = -1 :
	get: return _history_index
	set(value):
		value = mini(maxi(value, 0), history.back_index)
		if _history_index == value: return
		_set_history_index(value)
		emit_roll_events()
func _set_history_index(value: int) -> void:
	_history_index = value
var history_cursor : Record :
	get:
		assert(_history_index >= 0 and _history_index < history.records.size(), "Attempted to access history cursor while no records exist.")
		return history.records[history_index]

var is_at_present : bool :
	get: return _history_index == history.back_index

var can_roll_back : bool :
	get: return history.get_roll_back_index(history_index) != -1
var can_roll_ahead : bool :
	get: return history.get_roll_ahead_index(history_index) != -1


func _init() -> void:
	history = History.new()

func _ready() -> void:
	history.record_added.connect(self.emit_roll_events.unbind(1))
	emit_roll_events()


func roll_ahead() -> void:
	if not can_roll_ahead: return

	history_index = history.get_roll_ahead_index(history_index)

func roll_back() -> void:
	if not can_roll_back: return

	history_index = history.get_roll_back_index(history_index)

func roll_end() -> void:
	history_index = history.back_index

func cull_ahead_in_place() -> void:
	history.cull_ahead(history_index)

func clear_history() -> void:
	history.records.clear()
	_history_index = history.back_index

func emit_roll_events() -> void:
	on_roll_ahead_disabled.emit(not can_roll_ahead)
	on_roll_back_disabled.emit(not can_roll_back)
