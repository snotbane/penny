
class_name PennyObject extends RefCounted

static var DEFAULT_OBJECT := PennyObject.new({
	'name_prefix': "<>",
	'name_suffix': "</>",
})

static var DEFAULT_DATA := {
	'name_prefix': "<>",
	'name_suffix': "</>",
}

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
	# if not data.has(BASE_KEY) and self != DEFAULT_OBJECT:
	# 	data[BASE_KEY] = DEFAULT_OBJECT

func _to_string() -> String:
	return rich_name

func get_data(key: StringName, local_only := false) -> Variant:
	if data.has(key):
		return data[key]
	if data.has(BASE_KEY):
		return data[BASE_KEY].get_data(key)
	if DEFAULT_DATA.has(key):
		return DEFAULT_DATA[key]
	return null

func set_data(key: StringName, value: Variant) -> void:
	if value == null:
		data.erase(key)
	else:
		data[key] = value

func create_tree_item(tree: DataViewerTree, parent: TreeItem = null, path := ObjectPath.new()) -> TreeItem:
	var result := tree.create_item(parent)
	result.set_selectable(0, false)
	result.set_selectable(1, false)
	if path.identifiers:
		result.set_text(0, path.identifiers.back())
	# result.collapsed = true

	for k in data.keys():
		var v : Variant = data[k]
		if v is PennyObject:
			var ipath := path.duplicate()
			ipath.identifiers.push_back(k)
			v.create_tree_item(tree, result, ipath)
		else:
			var prop := result.create_child()
			prop.set_selectable(0, false)
			prop.set_selectable(1, false)
			prop.set_text(0, k)
			prop.set_text(1, Penny.get_debug_string(v))
	return result
