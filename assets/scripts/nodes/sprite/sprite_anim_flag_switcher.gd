
class_name SpriteAnimFlagSwitcher extends Node

@export var controllers : Array[SpriteFramesController]

var _flag := &"neutral"
var flag := &"neutral" :
	get: return _flag
	set(value):
		if _flag == value: return
		_flag = value

		for controller in controllers:
			controller.flag = value


func set_flag(value : StringName) -> void:
	flag = value
