
class_name Load extends Object


static func any(json: Variant) -> Variant:
	if json is Dictionary:	return Load.dict(json)
	if json is Array:		return Load.array(json)
	if json is String:		return Load.string(json)
	return json


static func dict(json: Dictionary) -> Dictionary:
	var result : Dictionary = {}
	for k in json.keys():
		result[k] = Load.any(json[k])
	return result


static func array(json: Array) -> Array:
	var result : Array = []
	result.resize(json.size())
	for i in json.size():
		result[i] = Load.any(json[i])
	return result


static func string(json: String) -> Variant:
	if json.is_empty(): return String()
	if json.begins_with(Save.REF_PREFIX)	: return Path.new_from_load_json(json)
	if json.begins_with(Save.COLOR_PREFIX)	: return Color.html(json.substr(Save.COLOR_PREFIX.length()))
	return json
