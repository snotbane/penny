
class_name LookupTable extends Resource

@export var data : Dictionary

func _init() -> void:
	print("Init'd lookup table")

func get_data(key: StringName) -> Variant:
	if data.has(key):
		return data[key]
	return null
