class_name CellLink extends Node

const GROUP_PREFIX := &"_claimant_"

## This will determine the priority of the parent [Node] in its [Cell]'s instance list.
@export var priority : int = 0

var cell_path : Path
var _claimant : StringName
## When this [Node] is created, OR when the [Cell] matching this name is created, we will link our [member parent] to the [Cell]'s instance. If blank, use the parent's name as the claimant.
@export var claimant : StringName :
	get: return _claimant
	set(value):
		if value.is_empty(): value = parent.name

		parent.remove_from_group(claimant_group_name)

		_claimant = value
		cell_path = Path.new_from_string(_claimant)

		parent.add_to_group(claimant_group_name)

var claimant_group_name : StringName :
	get: return GROUP_PREFIX + claimant

var parent : Node :
	get: return get_parent()


func _ready() -> void:
	claimant = claimant

	var cell : Cell = cell_path.evaluate()
	if not cell: return

	cell.add_instance(parent)


func _exit_tree() -> void:
	var cell : Cell = cell_path.evaluate()
	if not cell: return

	cell.remove_instance(parent)

