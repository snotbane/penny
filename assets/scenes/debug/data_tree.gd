extends Tree

enum Sort {
	NONE,
	DEFAULT,
	RECENT,
}

enum {
	NAME,
	STORAGE,
	ICON,
	VALUE,
}


var root : TreeItem

var _search_query : String = ""
var search_query : String = "" :
	get: return _search_query
	set (value):
		_search_query = value
		refresh_search()


var _search_values : bool = true
var search_values : bool = true :
	get: return _search_values
	set (value):
		_search_values = value
		refresh_search()

var _filter_stored_only : bool = false
var filter_stored_only : bool = false :
	get: return _filter_stored_only
	set(value):
		if _filter_stored_only == value: return
		_filter_stored_only = value
		refresh_search()


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

	self.set_column_expand(ICON, false)
	self.set_column_expand(STORAGE, false)

	self.set_column_title(NAME, "Path")
	self.set_column_title_alignment(NAME, HORIZONTAL_ALIGNMENT_LEFT)

	self.set_column_expand_ratio(VALUE, 3)
	self.set_column_title(VALUE, "Value")
	self.set_column_title_alignment(VALUE, HORIZONTAL_ALIGNMENT_LEFT)

	refresh()


func refresh() -> void:
	self.clear()

	root = create_tree_item_for_cell(Cell.ROOT, sort_type)
	root.set_text(NAME, "root")
	refresh_search()


func create_tree_item_for_cell(cell: Cell, sort : Sort, parent: TreeItem = null) -> TreeItem:
	return create_tree_item_for_any(parent, cell.key_name, cell.data, sort, cell.is_stored_in_parent)

func create_tree_item_for_any(parent: TreeItem, key: StringName, value: Variant, sort: Sort, stored: bool) -> TreeItem:
	var result := self.create_item(parent)

	result.set_selectable(VALUE, false)
	result.set_text(VALUE, Penny.get_value_as_string(value))
	if value == null:
		result.set_custom_color(VALUE, Color(1, 1, 1, 0.125))
	elif value is Cell:
		stored = value.is_stored_in_parent
		for k in value.data:
			create_tree_item_for_any(result, k, value.data[k], sort, value.is_key_stored(k))
	elif value is Dictionary:
		for k in value:
			create_tree_item_for_any(result, k, value[k], sort, false)
	elif value is Array:
		result.collapsed = true
		for i in value.size():
			create_tree_item_for_any(result, str(i), value[i], Sort.NONE, false)
	elif value is Path:
		result.set_custom_color(VALUE, Path.COLOR)
	elif value is Color:
		result.set_custom_color(VALUE, value)

	result.set_selectable(NAME, false)
	result.set_text(NAME, key)

	result.set_selectable(STORAGE, false)
	result.set_cell_mode(STORAGE, TreeItem.CELL_MODE_ICON)
	var storage_icon := get_storage_icon(stored)
	if storage_icon:
		result.set_icon(STORAGE, storage_icon)
		result.set_tooltip_text(STORAGE, get_storage_tooltip(stored))

	result.set_selectable(ICON, false)
	result.set_cell_mode(ICON, TreeItem.CELL_MODE_ICON)
	var icon := get_icon(value)
	if icon:
		result.set_icon(ICON, icon)
		result.set_tooltip_text(ICON, get_icon_tooltip(value))

	return result

static func get_storage_icon(value: Variant) -> Texture2D:
	return preload("uid://bh14tq6l7jvmn") if value else null

static func get_storage_tooltip(value: Variant) -> String:
	return "This value will be saved." if value else ""

static func get_icon(value: Variant) -> Texture2D:
	if value is Cell:
		return preload("uid://dfir03166e6r2")
	if value is Dictionary:
		return preload("uid://b3yg388eo1tr4")
	if value is	Array:
		return preload("uid://brecacl0mws63")
	if value is	Color:
		return preload("uid://dpxsajvwjy3w6")
	if value is Path:
		return preload("uid://dn51yrr71rglp")
	if value is Expr:
		return preload("uid://bee45y5iclbot")
	if value is Node:
		return preload("uid://bovb503mwm2jf")
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
	if value is Path:
		return "ref"
	if value is Expr:
		return "expression"
	if value is Node:
		return "node"
	return "other"


func refresh_search() -> void:
	if search_query == "":
		set_visible_recursive(root, true)
	else:
		for i in root.get_children():
			set_visible_recursive_if_matched_query(i)


func set_visible_recursive(item: TreeItem, value: bool) -> void:
	item.visible = value
	for i in item.get_children():
		set_visible_recursive(i, value)


func set_visible_recursive_if_matched_query(item: TreeItem) -> bool:
	var result : bool = (item.get_text(NAME).containsn(search_query) \
		or (search_values and item.get_text(VALUE).containsn(search_query))) \
		and (not filter_stored_only or item.get_icon(STORAGE) != null)
	set_visible_recursive(item, result)
	if not result:
		for i in item.get_children():
			if set_visible_recursive_if_matched_query(i):
				result = true
		item.visible = result
	return result


func _search_values_toggled(value : bool) -> void:
	search_values = value

func _search_query_changed(value : String) -> void:
	search_query = value

func _sort_type_changed(value : int) -> void:
	sort_type = value as Sort

func _zoom_changed(value : float) -> void:
	font_size = floori(value)


func _search_storage_toggled(toggled_on: bool) -> void:
	filter_stored_only = toggled_on
