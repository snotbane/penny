
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

static var BUILTIN_DICT := {
	BUILTIN_OBJECT_NAME: BUILTIN_OBJECT,
	BUILTIN_OPTION_NAME: BUILTIN_OPTION,
	BUILTIN_PROMPT_NAME: BUILTIN_PROMPT,
}

static var BUILTIN_OBJECT := PennyObject.new(null, BUILTIN_OBJECT_NAME, {
	'name_prefix': "<>",
	'name_suffix': "</>",
})

static var BUILTIN_OPTION := PennyObject.new(null, BUILTIN_OPTION_NAME, {
	BASE_KEY: Path.new([BUILTIN_OBJECT_NAME]),
	ABLE_KEY: Path.new([USED_KEY], true),
	SHOW_KEY: true,
	# ICON_KEY: null,
	USED_KEY: false,
})

static var BUILTIN_PROMPT := PennyObject.new(null, BUILTIN_PROMPT_NAME, {
	BASE_KEY: Path.new([BUILTIN_OBJECT_NAME]),
	LINK_KEY: Lookup.new('menu_default'),
	OPTIONS_KEY: [],
	RESPONSE_KEY: -1,
})

static var PRIORITY_DATA_ENTRIES := [
	"base",
	"link",
	"name",
]

const BUILTIN_OBJECT_NAME := 'object'
const BUILTIN_OPTION_NAME := 'option'
const BUILTIN_PROMPT_NAME := 'prompt'
const ABLE_KEY := 'able'
const BASE_KEY := 'base'
const LINK_KEY := 'link'
const NAME_KEY := 'name'
const ICON_KEY := 'icon'
const OPTIONS_KEY := 'options'
const RESPONSE_KEY := 'response'
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

func _init(_host: PennyHost, _parent_key: StringName, _data : Dictionary = { BASE_KEY: Path.new([BUILTIN_OBJECT_NAME]) }) -> void:
	host = _host
	parent_key = _parent_key
	data = _data

func _to_string() -> String:
	return rich_name

func get_data(key: StringName) -> Variant:
	if data.has(key):
		return data[key]
	if host and data.has(BASE_KEY):
		var base = data[BASE_KEY]
		if base is Path:
			var path : Path = base.duplicate()
			path.identifiers.push_back(key)
			return path.evaluate(host)
		return base
	return null

func set_data(key: StringName, value: Variant) -> void:
	if value == null:
		data.erase(key)
	else:
		data[key] = value

func has_data(key: StringName) -> bool:
	return data.has(key)

func open(_host: PennyHost) -> Node:
	var lookup : Lookup = get_data(LINK_KEY)
	if lookup:
		return lookup.open(_host)
	return null

func create_tree_item(tree: DataViewerTree, sort: Sort, parent: TreeItem = null, path := Path.new()) -> TreeItem:
	var result := tree.create_item(parent)

	result.set_selectable(TreeCell.ICON, false)
	result.set_cell_mode(TreeCell.ICON, TreeItem.CELL_MODE_ICON)
	result.set_icon(TreeCell.ICON, load("res://addons/penny_godot/assets/icons/Object.svg"))

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
		# Sort.NONE:		keys.reverse()
		Sort.DEFAULT:	keys.sort()
	keys.sort_custom(sort_baseline)

	for k in keys:
		var v : Variant = data[k]
		if v is PennyObject:
			var ipath := path.duplicate()
			ipath.identifiers.push_back(k)
			v.create_tree_item(tree, sort, result, ipath)
		else:
			var prop := create_tree_item_property(tree, result, str(k), v)

	return result

func create_tree_item_property(tree: DataViewerTree, parent: TreeItem, k: StringName, v: Variant) -> TreeItem:
	var prop = parent.create_child()

	prop.set_selectable(TreeCell.ICON, false)
	prop.set_cell_mode(TreeCell.ICON, TreeItem.CELL_MODE_ICON)

	prop.set_selectable(TreeCell.NAME, false)
	prop.set_text(TreeCell.NAME, k)

	prop.set_selectable(TreeCell.VALUE, false)
	var icon := get_icon(v)
	if icon:
		prop.set_icon(TreeCell.ICON, icon)
		prop.set_tooltip_text(TreeCell.ICON, get_tooltip(v))
	prop.set_text(TreeCell.VALUE, Penny.get_debug_string(v))
	if v is Color:
		prop.set_custom_color(TreeCell.VALUE, v)
		# prop.set_custom_bg_color(TreeCell.VALUE, Color.from_hsv(0, 0, wrap(v.v + 0.5, 0, 1)))
	elif v is Array:
		prop.collapsed = true
		for i in v.size():
			create_tree_item_property(tree, prop, str(i), v[i])
	return prop

static func sort_baseline(a, b) -> int:
	return PRIORITY_DATA_ENTRIES.find(a) > PRIORITY_DATA_ENTRIES.find(b)

## REALLY SLOW??? PROBABLY??? Try caching
static func get_icon(value: Variant) -> Texture2D:
	if value is	Array:
		return load("res://addons/penny_godot/assets/icons/Array.svg")
	if value is	Color:
		return load("res://addons/penny_godot/assets/icons/Color.svg")
	if value is Path:
		return load("res://addons/penny_godot/assets/icons/Path.svg")
	if value is Lookup:
		return load("res://addons/penny_godot/assets/icons/Lookup.svg")
	if value is Expr:
		return load("res://addons/penny_godot/assets/icons/PrismMesh.svg")
	return null

static func get_tooltip(value: Variant) -> String:
	if value is Array:
		return "array"
	if value is Color:
		return "color"
	if value is Path:
		return "path"
	if value is Lookup:
		return "lookup"
	if value is Expr:
		return "expression"
	return "other"
