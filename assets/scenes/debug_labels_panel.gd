extends Control

@export_file var label_listing_path := "res://addons/penny_godot/assets/scenes/debug_label_listing.tscn"
var label_listing_scene : PackedScene :
	get: return load(label_listing_path)

@onready var container := $panel_container/margin_container/scroll_container/label_listing_container

var _search_query : String = ""
var search_query : String = "" :
	get: return _search_query
	set (value):
		_search_query = value
		refresh_search()


func _ready() -> void:
	Penny.inst.on_reload_finish.connect(refresh.unbind(1))


func refresh() -> void:
	for child in container.get_children():
		child.queue_free()
	for label in Penny.labels:
		var node := label_listing_scene.instantiate()
		node.populate(label)
		container.add_child(node)


func refresh_search() -> void:
	if search_query == "":
		for child in container.get_children():
			child.visible = true
	else:
		for child in container.get_children():
			child.visible = child.label_name.containsn(search_query)


#region Events
func _search_query_changed(s: String) -> void:
	search_query = s
#endregion
