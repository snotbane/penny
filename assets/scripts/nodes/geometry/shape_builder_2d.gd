@tool class_name ShapeBuilder2D extends Node2D

var _color := Color.WHITE
@export var color := Color.WHITE :
	get: return _color
	set(value):
		if _color == value: return
		_color = value
		queue_redraw()

func _ready() -> void: pass
