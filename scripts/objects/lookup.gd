
class_name Lookup extends RefCounted

var key : StringName

func _init(_key: StringName) -> void:
	key = _key

func _to_string() -> String:
	return key
