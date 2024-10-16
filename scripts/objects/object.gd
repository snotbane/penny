
class_name PennyObject extends RefCounted

enum Sort {
	NONE,
	DEFAULT,
	RECENT,
}

enum TreeCell {
	NAME,
	ICON,
	VALUE
}

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

func create_tree_item(tree: DataViewerTree, sort: Sort, parent: TreeItem = null, path := ObjectPath.new()) -> TreeItem:
	var result := tree.create_item(parent)

	result.set_selectable(TreeCell.ICON, false)
	result.set_cell_mode(TreeCell.ICON, TreeItem.CELL_MODE_ICON)
	result.set_icon(TreeCell.ICON, load("res://addons/penny_godot/assets/icons/Node.svg"))

	result.set_selectable(TreeCell.NAME, false)

	result.set_selectable(TreeCell.VALUE, false)

	if path.identifiers:
		result.set_text(TreeCell.NAME, path.identifiers.back())
		if host:
			var v : Variant = path.get_data(host)
			if v is PennyObject:
				result.set_text(TreeCell.VALUE, v.name)
	# result.collapsed = true

	var keys := data.keys()
	match sort:
		Sort.NONE:
			keys.reverse()
		Sort.DEFAULT:
			keys.sort()

	for k in keys:
		var v : Variant = data[k]
		if v is PennyObject:
			var ipath := path.duplicate()
			ipath.identifiers.push_back(k)
			v.create_tree_item(tree, sort, result, ipath)
		else:
			var prop := result.create_child()

			prop.set_selectable(TreeCell.ICON, false)
			prop.set_cell_mode(TreeCell.ICON, TreeItem.CELL_MODE_ICON)
			# prop.set_icon(TreeCell.ICON, load("res://addons/penny_godot/assets/icons/Variant.svg"))

			prop.set_selectable(TreeCell.NAME, false)
			prop.set_text(TreeCell.NAME, k)

			prop.set_selectable(TreeCell.VALUE, false)
			prop.set_text(TreeCell.VALUE, Penny.get_debug_string(v))
	return result
