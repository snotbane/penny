class_name PennyDebugTree
extends Tree

const COLOR_DIM := Color(1, 1, 1, 0.25)


static func get_value_string(value: Variant) -> String:
	if value == null:
		return "NULL"

	if value is Penny.Cell:
		return value.name

	if value is Color:
		return "#" + value.to_html()

	return str(value)


var root: TreeItem


func _init() -> void:
	visibility_changed.connect((func() -> void:
		if visible:
			refresh()
	))


func _ready() -> void:
	refresh()


func refresh() -> void:
	clear()
	_construct_tree()


func _construct_tree() -> void:
	pass


var filter_text: String = ""


func refresh_filter() -> void:
	filter_recursive(root)

func set_filter(new_text: String) -> void:
	filter_text = new_text
	filter_recursive(root)


func filter_recursive(item: TreeItem) -> void:
	if filter_text == "":
		item.visible = true

	else:
		_filter_item(item)

	if item.visible:
		item.clear_custom_color(0)
	else:
		item.set_custom_color(0, COLOR_DIM)

	for i in item.get_children():
		filter_recursive(i)
		if not item.visible and i.visible:
			item.visible = true


func _filter_item(item: TreeItem) -> void:
	item.visible = item.get_text(0).containsn(filter_text)
