extends PennyDebugTree

enum {
	COLUMN_NAME,
	COLUMN_STORAGE,
	COLUMN_ICON,
	COLUMN_VALUE,

	COLUMN_MAX
}

const COLUMN_NAMES : PackedStringArray = [
	"Path",
	"",
	"",
	"Value",
]


const PRIORITY_KEYS_REVERSED : PackedStringArray = [
	"filters",
	"dialog",
	"prototype",
	"name",
	"object",
]

static func get_name_tooltip(text: String) -> String:
	match text:
		"name": return "The display name of this object. This is what will be displayed in [Penny.Message]s."
		"dialog": return "The path to the object which this object instantiates when it speaks."
		"filters": return "An array of [Penny.Text.Filter]s. Each one will perform a [RegEx] search-and-replace operation\non any [Penny.Message] spoken by this object. These apply iteratively, so order matters!"
		"object": return "The base object. All other objects inherit from this, so\nchanging values here will effectively change them globally."
		"prototype": return "The path to the object which this object inherits values from."

	return ""


static func get_name_color(text: String) -> Variant:
	if text in PRIORITY_KEYS_REVERSED:
		return Color.html("ffca5f")
	else:
		return null


static func get_icon(value: Variant) -> Texture2D:
	if value == null:
		return null
	if value is Node:
		return preload("res://addons/penny/icons/Node.svg")
	if value is Penny.Cell:
		return preload("res://addons/penny/icons/Cell.svg")
	if value is Dictionary:
		return preload("res://addons/penny/icons/Dictionary.svg")
	if value is	Array:
		return preload("res://addons/penny/icons/Array.svg")
	if value is	Color:
		return preload("res://addons/penny/icons/Color.svg")
	if value is Penny.Path:
		return preload("res://addons/penny/icons/Path.svg")
	if value is Penny.Express:
		return preload("res://addons/penny/icons/Express.svg")
	if value is Penny.Message:
		return preload("res://addons/penny/icons/Message.svg")
	if value is Penny.Text:
		return preload("res://addons/penny/icons/Text.svg")
	if value is Penny.Text.Filter:
		return preload("res://addons/penny/icons/Filter.svg")
	if value is String:
		if ResourceLoader.exists(value):
			return preload("res://addons/penny/icons/ResourceScene.svg")
		else:
			return preload("res://addons/penny/icons/String.svg")
	if value is int or value is float:
		return preload("res://addons/penny/icons/Number.svg")

	return null


static func get_icon_tooltip(value: Variant) -> String:
	if value is Node:
		return "Node"
	if value is Penny.Cell:
		return "Penny.Cell"
	if value is Dictionary:
		return "Dictionary"
	if value is Array:
		return "Array"
	if value is Color:
		return "Color"
	if value is Penny.Path:
		return "Penny.Path"
	if value is Penny.Express:
		return "Penny.Express"
	if value is Penny.Message:
		return "Penny.Message"
	if value is Penny.Text:
		return "Penny.Text"
	if value is Penny.Text.Filter:
		return "Penny.Text.Filter"
	if value is String:
		if ResourceLoader.exists(value):
			return "Resource (as String)"
		else:
			return "String"
	if value is int or value is float:
		return "Number"
	return type_string(typeof(value))


static func get_storage_icon(value: Variant) -> Texture2D:
	return preload("res://addons/penny/icons/Storage.svg")

static func get_storage_tooltip(value: Variant) -> String:
	match value:
		0: return "[ UNSAVED ] This value will be reset when the application is closed."
		1: return "[ SAVED ] This value is saved and will persist within save files."
		2: return "[ SAVED ] A parent [Penny.Cell] is saved, so this will inherently be saved along with it."
	return ""



static func sorted(dict: Dictionary) -> Dictionary:
	var result := {}

	var keys := dict.keys()
	keys.sort_custom((func(a, b) -> bool:
		var ai := PRIORITY_KEYS_REVERSED.find(a)
		var bi := PRIORITY_KEYS_REVERSED.find(b)

		return a < b if ai == bi else ai > bi
	))
	for k in keys:
		result[k] = dict[k]

	return result


func _init() -> void:
	super._init()

	hide_root = true
	select_mode = Tree.SELECT_ROW

	columns = COLUMN_MAX
	for i in columns:
		set_column_title(i, COLUMN_NAMES[i])
		set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)

	set_column_expand(COLUMN_ICON, false)
	set_column_expand(COLUMN_STORAGE, false)

	set_column_expand_ratio(COLUMN_VALUE, 3)


func _construct_tree() -> void:
	root = create_variant_item(null, "root", Penny.Cell.ROOT)


func create_variant_item(
		parent: TreeItem,
		name: String,
		value: Variant,
		storage: int = 0,
		name_tooltip: String = ""
) -> TreeItem:
	var result := create_item(parent)
	result.set_text(COLUMN_NAME, name)
	result.set_tooltip_text(COLUMN_NAME, name_tooltip)
	result.set_selectable(COLUMN_NAME, false)
	var name_color = get_name_color(name)
	if name_color:
		result.set_custom_color(COLUMN_NAME, name_color)
	if name in PRIORITY_KEYS_REVERSED:
		result.collapsed = true

	result.set_selectable(COLUMN_STORAGE, false)
	result.set_cell_mode(COLUMN_STORAGE, TreeItem.CELL_MODE_ICON)
	var storage_icon := get_storage_icon(storage)
	if storage_icon:
		result.set_icon(COLUMN_STORAGE, storage_icon)
		result.set_tooltip_text(COLUMN_STORAGE, get_storage_tooltip(storage))
		match storage:
			2:
				result.set_icon_modulate(COLUMN_STORAGE, COLOR_DIM)
			0:
				result.set_icon_modulate(COLUMN_STORAGE, Color.TRANSPARENT)

	result.set_selectable(COLUMN_ICON, false)
	result.set_cell_mode(COLUMN_ICON, TreeItem.CELL_MODE_ICON)
	var icon := get_icon(value)
	if icon:
		result.set_icon(COLUMN_ICON, icon)
		result.set_tooltip_text(COLUMN_ICON, get_icon_tooltip(value))


	result.set_text(COLUMN_VALUE, get_value_string(value))
	result.set_selectable(COLUMN_VALUE, false)
	if value == null:
		result.set_custom_color(COLUMN_VALUE, COLOR_DIM)

	elif value is Penny.Cell:
		if result.get_text(COLUMN_VALUE) == value.name:
			result.set_text(COLUMN_VALUE, "")
		for k in sorted(value.data):
			var k_storage := int(value.get_is_data_saved(k))
			create_variant_item(
				result,
				k,
				value.get_data_local(k),
				1 if k_storage else 2 if storage else 0,
				get_name_tooltip(k)
			)

	elif value is Penny.Message:
		result.collapsed = true
		for t in value.translations:
			create_variant_item(
				result,
				("{%s}" % t) if t else "DEFAULT",
				value.translations[t]
			)

	elif value is Dictionary:
		for k in sorted(value):
			create_variant_item(result, str(k), value[k])

	elif value is Array:
		result.collapsed = true
		for i in value.size():
			create_variant_item(result, str(i), value[i])

	elif value is Penny.Path:
		result.set_custom_color(COLUMN_VALUE, Penny.Path.DEBUG_COLOR)

	elif value is Color:
		result.set_custom_color(COLUMN_VALUE, value)


	return result


var filter_mode: int = 1


func set_filter_mode(mode: int) -> void:
	filter_mode = mode
	filter_recursive(root)


func _filter_item(item: TreeItem) -> void:
	match filter_mode:
		0:
			item.visible = item.get_text(COLUMN_NAME).containsn(filter_text)
		1:
			item.visible = (
			item.get_text(COLUMN_NAME).containsn(filter_text)
			or item.get_text(COLUMN_VALUE).containsn(filter_text)
			or item.get_tooltip_text(COLUMN_ICON).containsn(filter_text)
		)
