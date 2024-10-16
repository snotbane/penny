
class_name PennyObject extends RefCounted

static var BASE_OBJECT := PennyObject.new(null, {
	'name_prefix': "<>",
	'name_suffix': "</>",
})

const BASE_OBJECT_NAME := "object"
const NAME_KEY := 'name'
const BASE_KEY := 'base'

var host : PennyHost
var data : Dictionary

var name : String :
	get: return str(get_data(NAME_KEY))

var rich_name : String :
	get: return str(get_data('name_prefix')) + name + str(get_data('name_suffix'))

func _init(_host: PennyHost, _data : Dictionary = { BASE_KEY: ObjectPath.new([BASE_OBJECT_NAME]) }) -> void:
	host = _host
	data = _data

func _to_string() -> String:
	return rich_name

func get_data(key: StringName) -> Variant:
	if data.has(key):
		return data[key]
	if host and data.has(BASE_KEY):
		var path : ObjectPath = data[BASE_KEY].duplicate()
		path.identifiers.push_back(key)
		return path.get_data(host)
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
