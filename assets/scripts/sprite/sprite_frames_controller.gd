
class_name SpriteFramesController extends Node

@onready var sprite : AnimatedSprite2D = self.get_parent()

var viable_flags : Array[StringName]

var _flag := &"neutral"
var flag := &"neutral" :
	get:
		return _flag
	set(value):
		if not viable_flags.has(value): return
		if _flag == value: return
		_flag = value
		refresh_current_anim()

var _state : StringName
var state : StringName = &"" :
	get: return _state
	set(value):
		if _state == value: return
		_state = value
		refresh_current_anim()

var final_anim_name : String :
	get:
		if _state == &"":
			return flag
		else:
			return flag + ("" if flag == &"" else "_") + _state


func _ready() -> void:
	for anim_name in sprite.sprite_frames.get_animation_names():
		var query := anim_name.substr(0, anim_name.find("_"))
		if viable_flags.has(query): continue
		viable_flags.push_back(query)


func refresh_current_anim() -> void:
	var anim_name = final_anim_name
	if not sprite or not sprite.sprite_frames.has_animation(anim_name) or sprite.animation == anim_name: return
	sprite.play(anim_name)
