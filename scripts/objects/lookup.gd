
class_name Lookup extends RefCounted

var key : StringName

var valid : bool :
	get: return LookupTable.has(key)

func _init(_key: StringName) -> void:
	key = _key

func _to_string() -> String:
	return "$" + key

func fetch() -> Variant:
	return LookupTable.get_data(key)
