
class_name SpriteFramesController extends Node

@onready var sprite : FlagSprite2D = self.get_parent()

func _ready() -> void:
	sprite.animation_finished.connect(_animation_finished)


func _animation_finished() -> void: pass
