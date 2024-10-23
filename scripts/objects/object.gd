
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
	BILTIN_OBJECT_NAME: BILTIN_OBJECT,
	BILTIN_OPTION_NAME: BILTIN_OPTION,
	BILTIN_PROMPT_NAME: BILTIN_PROMPT,
}

static var BILTIN_OBJECT := PennyObject.new(null, BILTIN_OBJECT_NAME, {
	'name_prefix': "<>",							## Prepended when getting the rich name.
	'name_suffix': "</>",							## Appended when getting the rich name.
	'dialog': Path.new([BILTIN_DIALOG_NAME]),		## Lookup for the message box scene.
	# 'dialog_shared': true,							## Whether or not to use a shared message box. All objects that have this set to true will share one message box object that won't be destroyed until someone who doesn't share decides to send dialog.
	# 'inst': null									## Reference to the instanced node of this object.
})

static var BILTIN_OPTION := PennyObject.new(null, BILTIN_OPTION_NAME, {
	BASE_KEY: Path.new([BILTIN_OBJECT_NAME]),
	ABLE_KEY: Path.new([USED_KEY], true),
	SHOW_KEY: true,
	# ICON_KEY: null,
	USED_KEY: false,
})

static var BILTIN_PROMPT := PennyObject.new(null, BILTIN_PROMPT_NAME, {
	BASE_KEY: Path.new([BILTIN_OBJECT_NAME]),
	LINK_KEY: Lookup.new('prompt_default'),
	OPTIONS_KEY: [],
	RESPONSE_KEY: -1,
})

static var BILTIN_DIALOG := PennyObject.new(null, BILTIN_DIALOG_NAME, {
	BASE_KEY: Path.new([BILTIN_OBJECT_NAME]),
	LINK_KEY: Lookup.new('dialog_default'),
	LINK_LAYER_KEY: 0,								## Prefer the bottom layer.
})

static var PRIORITY_DATA_ENTRIES := [
	"base",
	"link",
	"name",
]

const BILTIN_OBJECT_NAME := StringName('object')
const BILTIN_OPTION_NAME := StringName('option')
const BILTIN_PROMPT_NAME := StringName('prompt')
const BILTIN_DIALOG_NAME := StringName('dialog')
const ABLE_KEY := StringName('able')
const BASE_KEY := StringName('base')
const LINK_KEY := StringName('link')
const LINK_LAYER_KEY := StringName('link_layer')
const NAME_KEY := StringName('name')
const ICON_KEY := StringName('icon')
const INST_KEY := StringName('inst')
const OPTIONS_KEY := StringName('options')
const RESPONSE_KEY := StringName('response')
const SHOW_KEY := StringName('show')
const USED_KEY := StringName('used')

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

var preferred_layer : int :
	get:
		var value = get_data(LINK_LAYER_KEY)
		if value != null:
			return value
		return -1

static func _static_init() -> void:
	PRIORITY_DATA_ENTRIES.reverse()

func _init(_host: PennyHost, _parent_key: StringName, _data : Dictionary = { BASE_KEY: Path.new([BILTIN_OBJECT_NAME]) }) -> void:
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

func instantiate(_host: PennyHost) -> PennyNode:
	var lookup : Lookup = get_data(LINK_KEY)
	if lookup:
		var node : PennyNode = lookup.instantiate(_host, preferred_layer, self)
		set_data(INST_KEY, node)
		return node
	return null

func destroy_instance(_host: PennyHost, recursive: bool = false) -> void:
	if recursive:
		for k in data.keys():
			var v = data[k]
			if v is PennyObject:
				v.destroy_instance(_host, recursive)
	var node : PennyNode = get_data(INST_KEY)
	if node:
		node.queue_free()

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
