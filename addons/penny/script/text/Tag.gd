## A group of [Penny.Text.Decoration]s.
@tool
extends Resource

enum {
	MODE_ADDITIVE,
	MODE_SUBTRACTIVE,
}

@export_storage
var mode: int

@export_storage
var decorations: Array[Penny.Text.DecInst]


func _init(__mode__: int = MODE_ADDITIVE) -> void:
	mode = __mode__
	decorations = []


func add_decoration(decoration: Penny.Text.DecInst) -> void:
	for d in decorations:
		if decoration.id == d.id:
			printerr("A duplicate decoration '%s' already exists in this tag. It will be ignored." % decoration.id)
			return

	decoration.populate()
	decorations.push_back(decoration)
