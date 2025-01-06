
class_name Save extends Object

static func any(value: Variant, use_path_for_objects: bool = false) -> Variant:
	if value is Object:		return Save.object(value, use_path_for_objects)
	if value is Dictionary:	return Save.dict(value, use_path_for_objects)
	if value is Array:		return Save.array(value, use_path_for_objects)
	if value is Color:		return Save.color(value)
	return value


static func object(value: Object, use_path_for_objects: bool = false) -> Variant:
	if value is PennyObject:
		print("value is PennyObject: use_path_for_objects: ", use_path_for_objects, " ", value.save_path())
		if use_path_for_objects:
			return value.save_path()
		else:
			return value.save_data()
	elif value.has_method("save_data"):
	# if value.has_method("save_data"):
		return value.save_data()
	elif value is Node:
		return node(value)
	else:
		return null


static func node(value: Node) -> Dictionary:
	return {
		"name": value.name,
		"parent": value.get_parent().name
	}


static func dict(value: Dictionary, use_path_for_objects: bool = false) -> Dictionary:
	var result : Dictionary = {}
	for k in value.keys():
		result[k] = Save.any(value[k], use_path_for_objects)
	return result


static func array(value: Array, use_path_for_objects: bool = false) -> Array:
	var result : Array = []
	result.resize(value.size())
	for i in value.size():
		result[i] = Save.any(value[i], use_path_for_objects)
	return result


static func color(value: Color) -> String:
	return "color::#" + value.to_html(true)
