## Creates an alias to bundle multiple decorations into one.
@tool
class_name PennyComboDecoration
extends PennyDecoration

# @export_custom(PROPERTY_HINT_RESOURCE_TYPE, "PennyDecorationInstance")
@export
var instances : Array[PennyDecorationInstance]
