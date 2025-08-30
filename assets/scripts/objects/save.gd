
class_name Save extends Object

const REF_PREFIX := "ref::"
const COLOR_PREFIX := "col::#"
const CELL_PREFIX := "cell::"

static func any(value: Variant, use_cell_refs: bool = false) -> Variant:
	if value == null: return null
	if value is Object:		return Save.object(value, use_cell_refs)
	if value is Dictionary:	return Save.dict(value, use_cell_refs)
	if value is Array:		return Save.array(value, use_cell_refs)
	if value is Color:		return Save.color(value)
	return value


static func object(value: Object, use_cell_refs: bool = false) -> Variant:
	if value is Cell:
		return Path.to(value).export_json() if use_cell_refs else value.export_json()
	elif value.has_method(&"export_json"):
		return value.export_json()
	elif value is Node:
		return Save.node(value)
	else:
		return null


static func node(value: Node) -> Dictionary:
	return {
		&"name": value.name,
		&"parent": value.get_parent().name
	}


static func dict(value: Dictionary, use_cell_refs: bool = false) -> Dictionary:
	var result : Dictionary = {}
	for k in value.keys():
		result[k] = Save.any(value[k], use_cell_refs)
	return result


static func array(value: Array, use_cell_refs: bool = false) -> Array:
	var result : Array = []
	result.resize(value.size())
	for i in value.size():
		result[i] = Save.any(value[i], use_cell_refs)
	return result


static func color(value: Color) -> String:
	return COLOR_PREFIX + value.to_html(true)
