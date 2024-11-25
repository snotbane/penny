extends VBoxContainer

@export var debug : PennyDebug
@export var label_listing_prefab : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PennyImporter.inst.on_reload_finish.connect(populate.unbind(1))

func populate() -> void:
	for child in self.get_children():
		child.queue_free()
	for label in Penny.labels:
		var node : DebugLabelListing = label_listing_prefab.instantiate()
		node.populate(debug, label)
		add_child(node)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
