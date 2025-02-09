
extends Tree

enum Sort {
	NONE,
	DEFAULT,
	RECENT,
}

enum Column {
	NAME,
	ICON,
	VALUE,
}


var root : TreeItem

var _filter_query : String = ""
var filter_query : String = "" :
	get: return _filter_query
	set (value):
		_filter_query = value
		refresh_filter()


var _filter_values : bool = true
var filter_values : bool = true :
	get: return _filter_values
	set (value):
		_filter_values = value
		refresh_filter()


var _sort_type := Sort.NONE
var sort_type := Sort.NONE :
	get: return _sort_type
	set (value):
		_sort_type = value
		refresh()


var font_size : int :
	get: return self.get_theme_font_size("font_size")
	set (value):
		self.add_theme_font_size_override("font_size", value)


func _ready() -> void:
	self.visibility_changed.connect(refresh)
	Penny.inst.on_root_cell_modified.connect(refresh)

	self.set_column_expand(Column.ICON, false)

	self.set_column_title(Column.NAME, "Path")
	self.set_column_title_alignment(Column.NAME, HORIZONTAL_ALIGNMENT_LEFT)

	self.set_column_expand_ratio(Column.VALUE, 3)
	self.set_column_title(Column.VALUE, "Value")
	self.set_column_title_alignment(Column.VALUE, HORIZONTAL_ALIGNMENT_LEFT)

	refresh()


func refresh() -> void:
	self.clear()

	root = create_tree_item_for_cell(Cell.ROOT, sort_type)
	root.set_text(Column.NAME, "root")
	refresh_filter()


func create_tree_item_for_cell(cell: Cell, sort : Sort, parent: TreeItem = null) -> TreeItem:
	return create_tree_item_for_any(parent, cell.key_name, cell.data, sort)

func create_tree_item_for_any(parent: TreeItem, key: StringName, value: Variant, sort: Sort) -> TreeItem:
	var result := self.create_item(parent)

	result.set_selectable(Column.NAME, false)
	result.set_text(Column.NAME, key)

	result.set_selectable(Column.ICON, false)
	result.set_cell_mode(Column.ICON, TreeItem.CELL_MODE_ICON)
	var icon := get_icon(value)
	if icon:
		result.set_icon(Column.ICON, icon)
		result.set_tooltip_text(Column.ICON, get_icon_tooltip(value))

	result.set_selectable(Column.VALUE, false)
	result.set_text(Column.VALUE, Penny.get_value_as_string(value))
	if value == null:
		result.set_custom_color(Column.VALUE, Color(1, 1, 1, 0.125))
	elif value is Cell:
		for k in value.data:
			create_tree_item_for_any(result, k, value.data[k], sort)
	elif value is Dictionary:
		for k in value:
			create_tree_item_for_any(result, k, value[k], sort)
	elif value is Array:
		result.collapsed = true
		for i in value.size():
			create_tree_item_for_any(result, str(i), value[i], Sort.NONE)
	elif value is Cell.Ref:
		result.set_custom_color(Column.VALUE, Cell.Ref.COLOR)
	elif value is Color:
		result.set_custom_color(Column.VALUE, value)

	return result

static func get_icon(value: Variant) -> Texture2D:
	if value is Cell:
		return preload("res://addons/penny_godot/assets/textures/icons/Object.svg")
	if value is Dictionary:
		return preload("res://addons/penny_godot/assets/textures/icons/Dictionary.svg")
	if value is	Array:
		return preload("res://addons/penny_godot/assets/textures/icons/Array.svg")
	if value is	Color:
		return preload("res://addons/penny_godot/assets/textures/icons/Color.svg")
	if value is Cell.Ref:
		return preload("res://addons/penny_godot/assets/textures/icons/Ref.svg")
	if value is Expr:
		return preload("res://addons/penny_godot/assets/textures/icons/PrismMesh.svg")
	if value is Node:
		return preload("res://addons/penny_godot/assets/textures/icons/Node.svg")
	return null


static func get_icon_tooltip(value: Variant) -> String:
	if value is Cell:
		return "cell"
	if value is Dictionary:
		return "dictionary"
	if value is Array:
		return "array"
	if value is Color:
		return "color"
	if value is Cell.Ref:
		return "ref"
	if value is Expr:
		return "expression"
	if value is Node:
		return "node"
	return "other"


func refresh_filter() -> void:
	if filter_query == "":
		set_visible_recursive(root, true)
	else:
		for i in root.get_children():
			set_visible_recursive_if_matched_query(i)


func set_visible_recursive(item: TreeItem, value: bool) -> void:
	item.visible = value
	for i in item.get_children():
		set_visible_recursive(i, value)


func set_visible_recursive_if_matched_query(item: TreeItem) -> bool:
	var result := item.get_text(Column.NAME).containsn(filter_query) or (filter_values and item.get_text(Column.VALUE).containsn(filter_query))
	set_visible_recursive(item, result)
	if not result:
		for i in item.get_children():
			if set_visible_recursive_if_matched_query(i):
				result = true
		item.visible = result
	return result


func _on_filter_values_toggled(value : bool) -> void:
	filter_values = value

func _on_filter_query_changed(value : String) -> void:
	filter_query = value

func _on_sort_type_changed(value : int) -> void:
	sort_type = value as Sort

func _on_font_size_changed(value : float) -> void:
	font_size = floori(value)