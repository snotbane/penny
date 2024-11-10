extends Control

@export var vbox : VBoxContainer
@export var none_available_node : Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# refresh()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func refresh() -> void:
	none_available_node.visible = PennyHost.insts.is_empty()

	for child in vbox.get_children():
		child.queue_free()

	for host in PennyHost.insts:
		var button := Button.new()
		button.text = host.name
		button.pressed.connect(select.bind(host))
		vbox.add_child.call_deferred(button)


func select(host: PennyHost) -> void:
	# PennyDebug.inst.host = host
	# tab switch
	pass

