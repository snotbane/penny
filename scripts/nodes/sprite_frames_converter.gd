
@tool
class_name SpriteFramesConverter extends Node

@export var create_reset : bool :
	set(value):
		if player.has_animation("RESET"):
			library_default.remove_animation("RESET")

		var anim := Animation.new()

		anim.length = 0.0

		anim.add_track(Animation.TrackType.TYPE_VALUE, 0)
		anim.value_track_set_update_mode(0, Animation.UpdateMode.UPDATE_DISCRETE)
		anim.track_set_path(0, ^".:sprite_frames")
		anim.track_insert_key(0, 0.0, sprite.sprite_frames)

		anim.add_track(Animation.TrackType.TYPE_VALUE, 1)
		anim.value_track_set_update_mode(1, Animation.UpdateMode.UPDATE_DISCRETE)
		anim.track_set_path(1, ^".:animation")
		anim.track_insert_key(1, 0.0, sprite.animation)

		anim.add_track(Animation.TrackType.TYPE_VALUE, 2)
		anim.value_track_set_update_mode(2, Animation.UpdateMode.UPDATE_DISCRETE)
		anim.track_set_path(2, ^".:frame")
		anim.track_insert_key(2, 0.0, 0)

		library_default.add_animation("RESET", anim)

@export var create_anims : bool :
	set(value):
		for anim_name in sprite.sprite_frames.get_animation_names():
			if player.has_animation(anim_name):
				library_default.remove_animation(anim_name)

			var anim := Animation.new()

			if sprite.sprite_frames.get_animation_loop(anim_name):
				anim.loop_mode = Animation.LOOP_LINEAR
			else:
				anim.loop_mode = Animation.LOOP_NONE

			anim.add_track(Animation.TrackType.TYPE_VALUE, 0)
			anim.value_track_set_update_mode(0, Animation.UpdateMode.UPDATE_DISCRETE)
			anim.track_set_path(0, ^".:animation")
			anim.track_insert_key(0, 0.0, anim_name)

			anim.add_track(Animation.TrackType.TYPE_VALUE, 1)
			anim.value_track_set_update_mode(1, Animation.UpdateMode.UPDATE_DISCRETE)
			anim.track_set_path(1, ^".:frame")

			var speed := 1.0 / sprite.sprite_frames.get_animation_speed(anim_name)
			var cursor := 0.0
			for i in sprite.sprite_frames.get_frame_count(anim_name):
				anim.track_insert_key(1, cursor, i)
				cursor += sprite.sprite_frames.get_frame_duration(anim_name, i) * speed

			anim.length = cursor

			library_default.add_animation(anim_name, anim)


@onready var sprite : AnimatedSprite2D = self.get_parent().get_parent()
@onready var player : AnimationPlayer = self.get_parent()
@onready var library_default : AnimationLibrary = player.get_animation_library("")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint(): queue_free()
	player.play.call_deferred("RESET")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
