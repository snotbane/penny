
class_name DataViewerTree extends Tree

@export var debug : PennyDebug

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.set_column_title(0, "Path")
	self.set_column_title(1, "Value")
	self.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	self.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)

func refresh() -> void:
	self.clear()

	if debug.host:
		var root := debug.host.data_root.create_tree_item(self)
		root.set_text(0, "root")
		# root.collapsed = false
