
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

static var STATIC_ROOT := PennyObject.new('static', {
	BILTIN_OBJECT_NAME: BILTIN_OBJECT,
	BILTIN_OPTION_NAME: BILTIN_OPTION,
	BILTIN_PROMPT_NAME: BILTIN_PROMPT,
	BILTIN_DIALOG_NAME: BILTIN_DIALOG,
})

static var BILTIN_OBJECT := PennyObject.new(BILTIN_OBJECT_NAME, {
	'name_prefix': "<>",							## Prepended when getting the rich name.
	'name_suffix': "</>",							## Appended when getting the rich name.
	'dialog': Path.new([BILTIN_DIALOG_NAME]),		## Lookup for the message box scene.
	# 'dialog_shared': true,							## Whether or not to use a shared message box. All objects that have this set to true will share one message box object that won't be destroyed until someone who doesn't share decides to send dialog.
	# 'inst': null									## Reference to the instanced node of this object.
})

static var BILTIN_OPTION := PennyObject.new(BILTIN_OPTION_NAME, {
	BASE_KEY: Path.new([BILTIN_OBJECT_NAME]),
	ABLE_KEY: Path.new([USED_KEY]),
	SHOW_KEY: true,
	# ICON_KEY: null,
	USED_KEY: false,
})

static var BILTIN_PROMPT := PennyObject.new(BILTIN_PROMPT_NAME, {
	BASE_KEY: Path.new([BILTIN_OBJECT_NAME]),
	LINK_KEY: Lookup.new('prompt_default'),
	OPTIONS_KEY: [],
	RESPONSE_KEY: -1,
})

static var BILTIN_DIALOG := PennyObject.new(BILTIN_DIALOG_NAME, {
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

var self_key : StringName
var data : Dictionary

var node_name : String :
	get: return "%s (penny)" % self_key

var preferred_layer : int :
	get:
		var value = get_local_from_key(LINK_LAYER_KEY)
		if value != null:
			return value
		return -1

static func _static_init() -> void:
	PRIORITY_DATA_ENTRIES.reverse()

func _init(_self_key: StringName, _data: Dictionary = { BASE_KEY: Path.new([BILTIN_OBJECT_NAME]) }) -> void:
	self_key = _self_key
	data = _data

func _to_string() -> String:
	return self_key

func get_local_from_key(key: StringName) -> Variant:
	if data.has(key):
		return data[key]
	if data.has(BASE_KEY):
		var path : Path = data[BASE_KEY].duplicate()
		path.ids.push_back(key)
		return path
	return null

func set_local_from_key(key: StringName, value: Variant) -> void:
	if value == null:
		data.erase(key)
	else:
		data[key] = value

func has_local(key: StringName) -> bool:
	return data.has(key)

func clear_local_from_key(key: StringName) -> void:
	set_local_from_key(key, null)

func get_from_path(path: Path, deep := true) -> Variant:
	if deep:
		return path.get_deep_value_for(self)
	else:
		return path.get_value_for(self)

func set_from_path(path: Path, value: Variant) -> void:
	path.set_value_for(self, value)

func has_path(path: Path) -> bool:
	return path.has_value_for(self)

func clear_from_path(path: Path) -> void:
	set_from_path(path, null)

func get_local_or_base_on_root(key: StringName, root: PennyObject) -> Variant:
	if data.has(key):
		return data[key]
	var path := Path.from_single(key, true)
	path.prepend(data[BASE_KEY])
	return root.get_from_path(path)

func get_rich_name(root: PennyObject) -> String:

	return get_local_or_base_on_root('name_prefix', root) + get_local_or_base_on_root('name', root) + get_local_or_base_on_root('name_suffix', root)
	# var name_prefix_path := Path.new(['name_prefix'])
	# return name_prefix_path.get_deep_value_for(root)


func instantiate(_host: PennyHost) -> Node:
	var result : Node = self.get_local_from_key(INST_KEY)
	print("inst: ", result)
	if result:
		_host.cursor.create_exception("Subject '%s' already has an instance '%s'. Aborting." % [self, result]).push()
	else:
		var lookup : Lookup = get_local_from_key(LINK_KEY)
		print("lookup: ", lookup)
		result = lookup.instantiate(_host, self, preferred_layer)
		result.name = node_name
		print("result: ", result)
		self.set_local_from_key(INST_KEY, result)
	return result

func destroy_instance_downstream(_host: PennyHost, recursive: bool = false) -> void:
	if recursive:
		for k in data.keys():
			var v = data[k]
			if v and v is PennyObject:
				v.destroy_instance_downstream(_host, recursive)
	var node : PennyNode = get_local_from_key(INST_KEY)
	if node:
		node.queue_free()
	# clear_local_from_key(INST_KEY)

func clear_instance_upstream() -> void:
	clear_local_from_key(INST_KEY)

func create_tree_item(tree: DataViewerTree, sort: Sort, parent: TreeItem = null, path := Path.new()) -> TreeItem:
	var result := tree.create_item(parent)

	result.set_selectable(TreeCell.ICON, false)
	result.set_cell_mode(TreeCell.ICON, TreeItem.CELL_MODE_ICON)
	result.set_icon(TreeCell.ICON, load("res://addons/penny_godot/assets/icons/Object.svg"))

	result.set_selectable(TreeCell.NAME, false)

	result.set_selectable(TreeCell.VALUE, false)

	if path.ids:
		result.set_text(TreeCell.NAME, path.ids.back())
		# if host:
		# 	var v : Variant = path.get_local_from_key(host)
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
			ipath.ids.push_back(k)
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
