
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

static var DEFAULT_BASE := Path.from_single(BILTIN_OBJECT_NAME, false)

static var STATIC_ROOT := PennyObject.new(BILTIN_STATIC_NAME, null)

static var BILTIN_OBJECT := PennyObject.new(BILTIN_OBJECT_NAME, STATIC_ROOT, {
	NAME_KEY: "",
	NAME_PREFIX_KEY: "<>",							## Prepended when getting the rich name.
	NAME_SUFFIX_KEY: "</>",							## Appended when getting the rich name.
	DIALOG_KEY: Path.new([BILTIN_DIALOG_NAME]),		## Lookup for the message box scene.
	# 'dialog_shared': true,							## Whether or not to use a shared message box. All objects that have this set to true will share one message box object that won't be destroyed until someone who doesn't share decides to send dialog.
	# 'inst': null									## Reference to the instanced node of this object.
})

static var BILTIN_OPTION := PennyObject.new(BILTIN_OPTION_NAME, STATIC_ROOT, {
	BASE_KEY: Path.new([BILTIN_OBJECT_NAME]),
	ABLE_KEY: Path.new([USED_KEY], true),
	SHOW_KEY: true,
	# ICON_KEY: null,
	USED_KEY: false,
})

static var BILTIN_PROMPT := PennyObject.new(BILTIN_PROMPT_NAME, STATIC_ROOT, {
	BASE_KEY: Path.new([BILTIN_OBJECT_NAME]),
	LINK_KEY: Lookup.new(StringName('prompt_default')),
	OPTIONS_KEY: [],
	RESPONSE_KEY: -1,
})

static var BILTIN_DIALOG := PennyObject.new(BILTIN_DIALOG_NAME, STATIC_ROOT, {
	BASE_KEY: Path.new([BILTIN_OBJECT_NAME]),
	LINK_KEY: Lookup.new(StringName('dialog_default')),
	LINK_LAYER_KEY: 0,								## Prefer the bottom layer.
})


static var PRIORITY_DATA_ENTRIES := [
	BASE_KEY,
	LINK_KEY,
	NAME_KEY,
]

const BILTIN_STATIC_NAME := StringName('static')
const BILTIN_OBJECT_NAME := StringName('object')
const BILTIN_OPTION_NAME := StringName('option')
const BILTIN_PROMPT_NAME := StringName('prompt')
const BILTIN_DIALOG_NAME := StringName('dialog')
const ABLE_KEY := StringName('able')
const BASE_KEY := StringName('base')
const COLOR_KEY := StringName('color')
const DIALOG_KEY := BILTIN_DIALOG_NAME
const FILTERS_KEY := StringName('filters')
const FILTER_PATTERN_KEY := StringName('pattern')
const FILTER_REPLACE_KEY := StringName('replace')
const LINK_KEY := StringName('link')
const LINK_LAYER_KEY := StringName('link_layer')
const NAME_KEY := StringName('name')
const NAME_PREFIX_KEY := StringName('name_prefix')
const NAME_SUFFIX_KEY := StringName('name_suffix')
const ICON_KEY := StringName('icon')
const INST_KEY := StringName('inst')
const OPTIONS_KEY := StringName('options')
const RESPONSE_KEY := StringName('response')
const SHOW_KEY := StringName('show')
const USED_KEY := StringName('used')

var parent : PennyObject
var self_key : StringName
var data : Dictionary

var name : FilteredText :
	get: return FilteredText.from_raw(self.get_value_or_default(NAME_KEY, self_key), self)

var name_prefix : FilteredText :
	get: return FilteredText.from_raw(self.get_value_or_default(NAME_PREFIX_KEY, "<>"), self)

var name_suffix : FilteredText :
	get: return FilteredText.from_raw(self.get_value_or_default(NAME_SUFFIX_KEY, "</>"), self)

var rich_name : FilteredText :
	get: return FilteredText.from_many([name_prefix, name, name_suffix])


var node_name : String :
	get: return "%s (penny)" % name


var preferred_layer : int :
	get:
		return get_value_or_default(LINK_LAYER_KEY, -1)


## Returns the ultimate ancestor of this object.
var root : PennyObject :
	get:
		var result := self
		while result.parent:
			result = result.parent
		return result


static func _static_init() -> void:
	STATIC_ROOT.data = {
		BILTIN_OBJECT_NAME: BILTIN_OBJECT,
		BILTIN_OPTION_NAME: BILTIN_OPTION,
		BILTIN_PROMPT_NAME: BILTIN_PROMPT,
		BILTIN_DIALOG_NAME: BILTIN_DIALOG,
	}
	PRIORITY_DATA_ENTRIES.reverse()


func _init(_self_key: StringName, _parent: PennyObject = null, _data: Dictionary = { BASE_KEY: Path.new([BILTIN_OBJECT_NAME]) }) -> void:
	self_key = _self_key
	parent = _parent
	data = _data


# func _to_string() -> String:
# 	return self_key


func duplicate(_new_parent: PennyObject = null, deep := false) -> PennyObject:
	return PennyObject.new(self_key, _new_parent, data.duplicate(deep))


## Returns the value stored in this object's [member data] using a given [key]. If it doesn't exist, return [null].
func get_local_value(key: StringName) -> Variant:
	if data.has(key):
		return data[key]
	return null


## Returns the inherited value from this object's base object using a given [key]. If it doesn't exist, return [null].
func get_base_value(key: StringName) -> Variant:
	var base : Path = self.get_local_value(BASE_KEY)
	if base == null: return null
	var path : Path = base.duplicate()
	path.ids.push_back(key)
	return path.evaluate(root)

## Returns the value stored in this object's [member data] using a given [key]. If it doesn't exist, look for it in the base (inherited) object.
func get_value(key: StringName) -> Variant:
	if self.has_local(key):
		return self.data[key]
	else:
		return self.get_base_value(key)


## Returns the value stored at the given [key], else use [default].
func get_local_value_or_default(key: StringName, default: Variant) -> Variant:
	if data.has(key):
		return data[key]
	else:
		return default

## Returns the value stored at the given [key], else use [default].
func get_value_or_default(key: StringName, default: Variant) -> Variant:
	var value : Variant = self.get_value(key)
	if value != null: return value
	return default


func set_value(key: StringName, value: Variant) -> void:
	if value == null:
		data.erase(key)
	else:
		data[key] = value


func add_object(key: StringName, base: Path = null) -> PennyObject:
	var initial_data := {}
	if base: initial_data[BASE_KEY] = base

	var result := PennyObject.new(key, self, initial_data)
	set_value(key, result)
	return result


func has_local(key: StringName) -> bool:
	return data.has(key)


func clear_local_from_key(key: StringName) -> void:
	set_value(key, null)


func get_or_create_node(_parent: Node, owner := self) -> Node:
	var result : Node = owner.local_instance
	if result: return result

	var lookup : Lookup = get_value(LINK_KEY)
	result = lookup.instantiate(_parent)
	result.name = owner.node_name
	owner.set_value(INST_KEY, result)

	return result


func instantiate_from_lookup(_parent: Node) -> Node:
	var result : Node = self.local_instance
	# if result and result is PennyNode and result.close_on_unlinked: self.local_instance.close()
	result = get_value(LINK_KEY).instantiate(_parent)
	result.name = self.node_name
	self.local_instance = result
	return result


var local_instance : Node :
	get: return self.get_local_value(INST_KEY)
	set(value): self.set_value(INST_KEY, value)


func destroy_instance_downstream(recursive: bool = false) -> void:
	if recursive:
		for k in data.keys():
			var v = data[k]
			if v and v is PennyObject:
				v.destroy_instance_downstream(recursive)
	var node : Node = get_value(INST_KEY)
	if node:
		node.queue_free()
	# clear_local_from_key(INST_KEY)


func clear_instance_upstream() -> void:
	clear_local_from_key(INST_KEY)


func create_tree_item(tree: DataViewerTree, sort: Sort, _parent: TreeItem = null, path := Path.new()) -> TreeItem:
	var result := tree.create_item(_parent)

	result.set_selectable(TreeCell.ICON, false)
	result.set_cell_mode(TreeCell.ICON, TreeItem.CELL_MODE_ICON)
	result.set_icon(TreeCell.ICON, load("res://addons/penny_godot/assets/icons/Object.svg"))

	result.set_selectable(TreeCell.NAME, false)

	result.set_selectable(TreeCell.VALUE, false)

	if path.ids:
		result.set_text(TreeCell.NAME, path.ids.back())
		# if host:
		# 	var v : Variant = path.get_value(host)
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
			create_tree_item_property(tree, result, str(k), v)

	return result


func create_tree_item_property(tree: DataViewerTree, _parent: TreeItem, k: StringName, v: Variant) -> TreeItem:
	var prop = _parent.create_child()

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
	if value is Node:
		return load("res://addons/penny_godot/assets/icons/Node.svg")
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
	if value is Node:
		return "node"
	return "other"
