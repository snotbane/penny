
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.set_column_title(0, "Path")
	self.set_column_title(1, "Value")
	self.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	self.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)

	setup.call_deferred()

func setup() -> void:
	debug.host.on_data_modified.connect(refresh)

func refresh() -> void:
	self.clear()

	if debug.host:
		root = debug.host.data_root.create_tree_item(self)
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

func _on_query_values_toggle_toggled(toggled_on:bool) -> void:
	search_values = toggled_on


func _on_data_search_bar_text_changed(new_text:String) -> void:
	query = new_text


func _on_sort_selector_item_selected(index:int) -> void:
	pass # Replace with function body.
