
## Links to a [PennyHost] and visualizes the [Record]s it produces.
class_name HistoryHandler extends Control

@export var scroll_container : ScrollContainer
@export var vbox : VBoxContainer

var scrollbar : VScrollBar :
	get: return scroll_container.get_v_scroll_bar()


var _host : PennyHost
@export var host : PennyHost :
	get: return _host
	set(value):
		if _host == value: return

		if _host:
			_host.history.record_added.disconnect(self.on_record_added)
			_host.history.record_removed.disconnect(self.on_record_removed)

		_host = value

		if _host:
			_host.history.record_added.connect(self.on_record_added)
			_host.history.record_removed.connect(self.on_record_removed)
			refresh()


var _verbosity : int
@export_flags(Stmt.VERBOSITY_NAMES[0], Stmt.VERBOSITY_NAMES[1], Stmt.VERBOSITY_NAMES[2], Stmt.VERBOSITY_NAMES[3], Stmt.VERBOSITY_NAMES[4], Stmt.VERBOSITY_NAMES[5]) var verbosity : int :
	get: return _verbosity
	set (value):
		_verbosity = value
		refresh_visibility()

# var controls : Array[PennyMessageLabel]


func refresh() -> void:
	for listing in vbox.get_children():
		listing.queue_free()
	for record in host.history.records:
		on_record_added(record)
	refresh_visibility()
	scroll_to_end.call_deferred()


func refresh_visibility() -> void:
	if not vbox: return
	for listing in vbox.get_children():
		listing.refresh_visibility(self)


func scroll_to_end() -> void:
	scrollbar.value = scrollbar.max_value


func on_record_added(record : Record) -> void:
	var listing := record.create_history_listing()
	listing.refresh_visibility(self)
	vbox.add_child(listing)


func on_record_removed(record : Record) -> void:
	for i in vbox.get_child_count():
		var listing : HistoryListing = vbox.get_child(-i-1)
		if listing.record == record:
			listing.queue_free()
			return


func _on_record_created(record : Record) -> void:
	on_record_added(record)


func _on_verbosity_selector_item_selected_id(id:int) -> void:
	self.verbosity = id



func _on_penny_debug_on_host_changed(__host: PennyHost) -> void:
	host = __host


