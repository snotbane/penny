## Abstract base class for displaying some element(s) from the global Penny History.
class_name HistoryUser extends Node

var _active_history : History
var active_history : History :
	get: return _active_history
	set(value):
		if _active_history == value: return
		_active_history = value

var _cursor_index : int
var cursor_index : int :
	get: return _cursor_index
	set(value):
		if _cursor_index == value: return
		_cursor_index = value
var cursor : Record :
	get: return _active_history.records[-cursor_index-1]
