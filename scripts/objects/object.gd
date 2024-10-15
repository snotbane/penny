
class_name PennyObject extends Object

const BASE_OBJECT_NAME = "object"

var host : PennyHost
var data : Dictionary

func _init(_host : PennyHost = null, _data : Dictionary = {}) -> void:
	host = _host
	data = _data

func _to_string() -> String:
	if data.has('name'):
		return get_data('name_prefix') + get_data('name') + get_data('name_suffix')
	return "Unnamed object <%s>" % self.get_instance_id()

func get_data(key: StringName) -> Variant:
	if data.has(key):
		return data[key]
	if data.has('base'):
		return data['base'].get_data(key)
	return null

func set_data(key: StringName, value: Variant) -> void:
	if value == null:
		if data.has(key) and data[key] is PennyObject:
			data[key].free()
		data.erase(key)
	else:
		data[key] = value

func add_obj(key: StringName, base: StringName = BASE_OBJECT_NAME) -> PennyObject:
	var result = PennyObject.new(null, {'base': host.data.get_data(base)})
	set_data(key, result)
	return result
