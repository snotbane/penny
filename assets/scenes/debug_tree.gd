class_name DebugTree extends Tree

var root : TreeItem

var _filter : String
var filter : String :
	get: return _filter
	set(value):
		if _filter == value: return
		_filter = value

		if _filter.is_empty():
			set_visible_recursive(root, true)
		else: for i in root.get_children():
			filter_recursive(i)
func set_filter(value: String) -> void:
	filter = value
func set_visible_recursive(item: TreeItem, value: bool) -> void:
	item.visible = value
	for i in item.get_children():
		set_visible_recursive(i, value)
func filter_recursive(item: TreeItem) -> bool:
	var result := false
	for i in _get_filter_columns():
		if item.get_text(i).containsn(_filter):
			result = true
			break
	set_visible_recursive(item, result)
	if not result:
		for i in item.get_children():
			if filter_recursive(i): result = true
		item.visible = result
	return result


var _sort : int
var sort : int :
	get: return _sort
	set(value):
		if _sort == value: return
		_sort = value

		if _sort <= 0:
			refresh()
		else:
			sort_recursive(root)
func set_sort(value: int) -> void:
	sort = value
func sort_recursive(item: TreeItem) -> void:
	var list := item.get_children()
	list.sort_custom(_get_sort_method(_sort))
	for i in list.size() - 1:
		list[i + 1].move_after(list[i])
		sort_recursive(list[i])
func _get_sort_method(idx: int) -> Callable: return _sort_alphabetic
func _sort_alphabetic(a: TreeItem, b: TreeItem) -> bool:
	return a.get_text(_get_sort_column()).to_lower() < b.get_text(_get_sort_column()).to_lower()
func _get_sort_column() -> int: return 0


func _get_filter_columns() -> Variant: return self.columns


func _ready() -> void:
	refresh()


func refresh() -> void:
	self.clear()
	root = self.create_item()

	if _sort > 0: sort_recursive.call_deferred(root)
