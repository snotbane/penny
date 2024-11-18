extends Control

signal on_selected

@export var vbox : VBoxContainer
@export var none_available_node : Control


func refresh() -> void:
	none_available_node.visible = PennyHost.insts.is_empty()

	for child in vbox.get_children():
		child.queue_free()

	for host in PennyHost.insts:
		var button := Button.new()
		button.text = host.name
		button.pressed.connect(self.select.bind(host))
		vbox.add_child.call_deferred(button)


func select(host: PennyHost) -> void:
	PennyDebug.inst.host = host
	on_selected.emit()

