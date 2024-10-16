
class_name PennyObject extends RefCounted

static var DEFAULT_OBJECT := PennyObject.new({
	'name_prefix': "<>",
	'name_suffix': "</>",
})

const BASE_OBJECT_NAME := "object"
const NAME_KEY := 'name'
const BASE_KEY := 'base'

var data : Dictionary

var name : String :
	get: return str(get_data(NAME_KEY))

var rich_name : String :
	get: return str(get_data('name_prefix')) + name + str(get_data('name_suffix'))

static func _static_init() -> void:
	DEFAULT_OBJECT.data.erase(PennyObject.BASE_KEY)

func _init(_data : Dictionary = {}) -> void:
	data = _data
	if not data.has(BASE_KEY):
		data[BASE_KEY] = DEFAULT_OBJECT

func _to_string() -> String:
	return rich_name

func get_data(key: StringName) -> Variant:
	if data.has(key):
		return data[key]
	if data.has(BASE_KEY):
		return data[BASE_KEY].get_data(key)
	return null

func set_data(key: StringName, value: Variant) -> void:
	if value == null:
		data.erase(key)
	else:
		data[key] = value
