
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

static var BASE_OBJECT := PennyObject.new(null, 'object', {
	'name_prefix': "<>",
	'name_suffix': "</>",
})

static var BASE_OPTION := PennyObject.new(null, 'option', {
	BASE_KEY: Path.new(["object"]),
	ABLE_KEY: true,
	SHOW_KEY: true,
	# ICON_KEY: null,
	USED_KEY: false,
})

static var PRIORITY_DATA_ENTRIES := [
	"base",
	"link",
	"name",
]

const BASE_OBJECT_NAME := "object"
const ABLE_KEY := 'able'
const BASE_KEY := 'base'
const NAME_KEY := 'name'
const ICON_KEY := 'icon'
const SHOW_KEY := 'show'
const USED_KEY := 'used'

var host : PennyHost
var parent_key : StringName
var data : Dictionary

var name : String :
	get:
		if has_data(NAME_KEY):
			return str(get_data(NAME_KEY))
		return String(parent_key)

var rich_name : String :
	get: return str(get_data('name_prefix')) + name + str(get_data('name_suffix'))

static func _static_init() -> void:
	PRIORITY_DATA_ENTRIES.reverse()

func _init(_host: PennyHost, _parent_key: StringName, _data : Dictionary = { BASE_KEY: Path.new([BASE_OBJECT_NAME]) }) -> void:
	host = _host
	parent_key = _parent_key
	data = _data

func _to_string() -> String:
	return rich_name

func get_data(key: StringName) -> Variant:
	if data.has(key):
		return data[key]
	if host and data.has(BASE_KEY):
		var path : Path = data[BASE_KEY].duplicate()
		path.identifiers.push_back(key)
		return path.get_data(host)
	return null

func set_data(key: StringName, value: Variant) -> void:
	if value == null:
		data.erase(key)
	else:
		data[key] = value

func has_data(key: StringName) -> bool:
	return data.has(key)

func create_tree_item(tree: DataViewerTree, sort: Sort, parent: TreeItem = null, path := Path.new()) -> TreeItem:
	var result := tree.create_item(parent)

	result.set_selectable(TreeCell.ICON, false)
	result.set_cell_mode(TreeCell.ICON, TreeItem.CELL_MODE_ICON)
	result.set_icon(TreeCell.ICON, load("res://addons/penny_godot/assets/icons/MiniObject.svg"))

	result.set_selectable(TreeCell.NAME, false)

	result.set_selectable(TreeCell.VALUE, false)

	if path.identifiers:
		result.set_text(TreeCell.NAME, path.identifiers.back())
		# if host:
		# 	var v : Variant = path.get_data(host)
		# 	if v is PennyObject:
		# 		result.set_text(TreeCell.VALUE, v.name)
	# result.collapsed = true

	var keys := data.keys()
	match sort:
		Sort.NONE:
			keys.reverse()
		Sort.DEFAULT:
			keys.sort()
	keys.sort_custom(sort_baseline)

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

			prop.set_selectable(TreeCell.NAME, false)
			prop.set_text(TreeCell.NAME, k)

			prop.set_selectable(TreeCell.VALUE, false)
			var icon := get_icon(v)
			if icon:
				prop.set_icon(TreeCell.ICON, icon)
			prop.set_text(TreeCell.VALUE, Penny.get_debug_string(v))
			if v is Color:
				prop.set_custom_color(TreeCell.VALUE, v)
				# prop.set_custom_bg_color(TreeCell.VALUE, Color.from_hsv(0, 0, wrap(v.v + 0.5, 0, 1)))
	return result

static func sort_baseline(a, b) -> int:
	return PRIORITY_DATA_ENTRIES.find(a) > PRIORITY_DATA_ENTRIES.find(b)

static func get_icon(value: Variant) -> Texture2D:
	if value is	Color:
		return load("res://addons/penny_godot/assets/icons/Color.svg")
	if value is Path:
		return load("res://addons/penny_godot/assets/icons/NodePath.svg")
	if value is Lookup:
		return load("res://addons/penny_godot/assets/icons/LinkButton.svg")
	if value is Expr:
		return load("res://addons/penny_godot/assets/icons/PrismMesh.svg")
	return null
