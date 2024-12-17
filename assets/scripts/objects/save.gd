
class_name Save extends Object

static func any(value: Variant) -> Variant:
	if value is Object:		return Save.object(value)
	if value is Dictionary:	return Save.dict(value)
	if value is Array:		return Save.array(value)
	if value is Color:		return Save.color(value)
	return value


static func object(value: Object) -> Variant:
	if value.has_method("save_data"):
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


static func dict(value: Dictionary) -> Dictionary:
	var result : Dictionary = {}
	for k in value.keys():
		result[k] = Save.any(value[k])
	return result


static func array(value: Array) -> Array:
	var result : Array = []
	result.resize(value.size())
	for i in value.size():
		result[i] = Save.any(value[i])
	return result


static func color(value: Color) -> String:
	return "#" + value.to_html(true)
