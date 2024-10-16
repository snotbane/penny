
class_name DataViewerTree extends Tree

@export var debug : PennyDebug


var root : TreeItem
var _query : String
var query : String :
	get: return _query
	set (value):
		_query = value
		refresh_search()


var _search_values : bool = true
var search_values : bool = true :
	get: return _search_values
	set (value):
		_search_values = value
		refresh_search()


var _sort_method := PennyObject.Sort.NONE
var sort_method := PennyObject.Sort.NONE :
	get: return _sort_method
	set (value):
		_sort_method = value
		refresh()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.set_column_expand(PennyObject.TreeCell.ICON, false)

	self.set_column_title(PennyObject.TreeCell.NAME, "Path")
	self.set_column_title_alignment(PennyObject.TreeCell.NAME, HORIZONTAL_ALIGNMENT_LEFT)

	self.set_column_expand_ratio(PennyObject.TreeCell.VALUE, 3)
	self.set_column_title(PennyObject.TreeCell.VALUE, "Value")
	self.set_column_title_alignment(PennyObject.TreeCell.VALUE, HORIZONTAL_ALIGNMENT_LEFT)

	setup.call_deferred()


func setup() -> void:
	debug.host.on_data_modified.connect(refresh)


func refresh() -> void:
	self.clear()

	if debug.host:
		root = debug.host.data_root.create_tree_item(self, sort_method)
		root.set_text(0, "root")

	refresh_search()


func refresh_search() -> void:
	if query == "":
		set_visible_recursive(root, true)
	else:
		for i in root.get_children():
			set_visible_if_matched_query(i, query)


func set_visible_if_matched_query(item: TreeItem, __query: String) -> bool:
	var result := item.get_text(0).containsn(query) or (search_values and item.get_text(1).containsn(query))
	set_visible_recursive(item, result)
	if not result:
		for i in item.get_children():
			if set_visible_if_matched_query(i, query):
				result = true
		item.visible = result
	return result


func set_visible_recursive(item: TreeItem, value: bool) -> void:
	item.visible = value
	for i in item.get_children():
		set_visible_recursive(i, value)


func _on_search_values_toggle_toggled(toggled_on:bool) -> void:
	search_values = toggled_on


func _on_search_bar_text_changed(new_text:String) -> void:
	query = new_text


func _on_sort_selector_item_selected(index:int) -> void:
	sort_method = index as PennyObject.Sort


func _on_search_clear_pressed() -> void:
	query = ""
