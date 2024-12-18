
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
	if json.begins_with("path::/")	: return Path.new_from_load_data(json)
	if json.begins_with("lookup::$"): return Lookup.new_from_load_data(json)
	if json.begins_with("color::#")	: return Color.html(json.substr("color::".length()))
	return json
