
## Text that has been interpolated, filtered, decorated, etc., and is ready to be displayed.
class_name DisplayString extends RefCounted

var text : String
var decos : Array[DecoInst]

func _init(_text : String = "", _decos: Array[DecoInst] = []) -> void:
	text = _text
	decos = _decos

