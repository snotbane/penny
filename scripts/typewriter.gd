class_name Typewriter extends Node

## Speed multiplier
@export var cps_multiplier : float = 1.0

@onready var rtl : RichTextLabel = get_parent()

var cursor_float : float = 0.0

var speed : float :
	get: return cps_multiplier * 60

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	cursor_float += speed * delta
	rtl.visible_characters = floori(cursor_float)

