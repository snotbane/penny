class_name JSONSerialize

#region Serialization

static var KNOWN_NONSERIALIZABLE_OBJECT_SCRIPTS : PackedStringArray = [
	"DisplayString",
]

static func serialize(value: Variant) -> Variant:
	if value == null: return null
	var result := {
		&"type": typeof(value),
		&"value": get_serial_value(value),
	}
	if typeof(value) == TYPE_OBJECT:
		result.merge({ &"class": value.get_class() })
		if value.get_script():
			result.merge({
				&"script": value.get_script().get_global_name(),
				&"script_uid": ResourceUID.id_to_text(ResourceLoader.get_resource_uid(value.get_script().resource_path)),
			})
	return result

static func get_serial_script(value: Variant) -> StringName:
	if value is not Object: return &""
	var script : Script = value.get_script()
	return script if script else value.get_class()

static func get_serial_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_OBJECT:		return _serialize_object(value)
		TYPE_DICTIONARY:	return _serialize_dictionary(value)
		TYPE_ARRAY:			return _serialize_array(value)
		TYPE_COLOR:			return value.to_html(true)
	return value

static func _serialize_object(value: Object) -> Variant:
	if value.has_method(&"export_json"):
		return value.export_json()
	elif value is Node:
		return {
			&"name": value.name,
			&"parent": value.get_parent().name,
		}

	assert(value.get_script() and value.get_script().get_global_name() in KNOWN_NONSERIALIZABLE_OBJECT_SCRIPTS, "Attempted to export an object (%s) to json that cannot be. Try adding an export_json() method to the object. Or, if this is expected, add the Script class_name to 'JSONSerialize.KNOWN_NONSERIALIZABLE_OBJECT_SCRIPTS'." % str(value))

	return null

static func _serialize_dictionary(value: Dictionary) -> Dictionary:
	var result := {}
	for k : Variant in value: result[k] = serialize(value[k])
	return result

static func _serialize_array(value: Array) -> Array:
	var result := []
	result.resize(value.size())
	for i in value.size(): result[i] = serialize(value[i], )
	return result

#endregion
#region Deserialization

static func deserialize(json: Variant) -> Variant:
	if json == null: return null

	match json[&"type"] as int:
		TYPE_OBJECT:		return _deserialize_object(json)
		TYPE_DICTIONARY:	return _deserialize_dictionary(json[&"value"])
		TYPE_ARRAY:			return _deserialize_array(json[&"value"])
		TYPE_COLOR:			return Color.html(json[&"value"])
		TYPE_INT:			return int(json[&"value"])

	return json[&"value"]

static func _deserialize_object(json: Dictionary) -> Variant:
	assert(json[&"script"] != &"Cell", "Cells should handle their own deserialization.")
	if json[&"script"] in KNOWN_NONSERIALIZABLE_OBJECT_SCRIPTS: return null

	var result : Object = ClassDB.instantiate(json[&"class"])
	if json.has(&"script") and json[&"value"] != null:
		result.set_script(load(json[&"script_uid"]))
		assert(result.get_script() != null, "Attempted to deserialize an object, but couldn't set the script. Make sure that it has an _init() method with 0 *required* arguments.")
		assert(result.has_method(&"import_json"), "Attempted to deserialize object '%s', but it has no 'import_json' method." % result)
		result.import_json(json[&"value"])

	return result

static func _deserialize_dictionary(json: Dictionary) -> Variant:
	var result : Dictionary = {}
	for k in json.keys():
		result[k] = deserialize(json[k])
	return result

static func _deserialize_array(json: Array) -> Variant:
	var result : Array = []
	result.resize(json.size())
	for i in json.size():
		result[i] = deserialize(json[i])
	return result


#endregion
