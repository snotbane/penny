@tool class_name ShapeBuilder3D extends MeshInstance3D

var _color := Color.WHITE
@export var color := Color.WHITE :
	get: return _color
	set(value):
		if _color == value: return
		_color = value
		Mesh


func _ready() -> void: pass
