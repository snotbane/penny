
class_name LookupTable extends Resource

static var data : Dictionary

@export var local_data : Dictionary

func _init() -> void:
	for k in local_data.keys():
		if data.has(k):
			Penny.log_error("LookupTable key '%s' already exists in another LookupTable. This key will not be added.")
	data.merge(local_data)

static func get_data(key: StringName) -> Variant:
	if data.has(key):
		return data[key]
	Penny.log_error("LookupTable key '%s' does not exist in any LookupTable.")
	return null

static func has(key: StringName) -> bool:
	return data.has(key)
