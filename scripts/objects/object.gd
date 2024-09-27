
class_name PennyObject extends Object

var host : PennyHost
var data : Dictionary

func _init(_host: PennyHost, _data : Dictionary = {}) -> void:
	host = _host
	data = _data

func _to_string() -> String:
	if data.has('name'):
		return get_data('name_prefix') + get_data('name') + get_data('name_suffix')
	return "Unnamed object <%s>" % self.get_instance_id()

func get_data(key: StringName) -> Variant:
	if data.has(key):
		return data[key]
	return host.get_data(key)
