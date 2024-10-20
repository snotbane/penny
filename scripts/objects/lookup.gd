
class_name Lookup extends RefCounted

var key : StringName

func _init(_key: StringName) -> void:
	key = _key

func _to_string() -> String:
	return "$" + key

func fetch(host: PennyHost) -> Variant:
	for i in host.lookup_tables:
		var value : Variant = i.get_data(key)
		if value:
			return value
	return null
