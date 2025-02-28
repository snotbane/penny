
class_name SpriteActor extends CellNode

signal flag_changed(value : StringName)
signal blinking_changed(value : bool)
signal talking_changed(value : bool)

@export var voice_audio_player : Node
@export var sprite_flags : FlagController
@export var sprite_blink_anim : Node


@export var is_blinking : bool :
	get: return sprite_blink_anim.is_blinking if sprite_blink_anim else false
	set(value):
		if not sprite_blink_anim: return
		sprite_blink_anim.is_blinking = value
		blinking_changed.emit(value)


@export var is_talking : bool :
	get: return sprite_flags.has_current_flag(&"talk") if sprite_flags else false
	set(value):
		if not sprite_flags: return
		sprite_flags.set_current_flag(&"talk" if value else &"silent")
		talking_changed.emit(value)



func _ready() -> void:
	super._ready()

	# if not self.flag_changed.is_connected(sprite_flags.set_current_flag):
	# 	self.flag_changed.connect(sprite_flags.set_current_flag)
	# 	self.talking_changed.connect(sprite_flags.set_talking_flag)


func set_is_talking(value: bool) -> void:
	is_talking = value
