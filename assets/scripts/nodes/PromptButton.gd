
class_name PennyPromptButton extends Actor

signal pressed

var _consumed : bool
var consumed : bool :
	get: return _consumed
	set(value):
		if _consumed == value: return
		_consumed = value
		_set_consumed(_consumed)
func _set_consumed(value: bool) -> void: pass

func _ready() -> void: pass

# func _pressed() -> void: pass