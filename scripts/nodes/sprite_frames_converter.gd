
@tool
class_name SpriteFramesConverter extends Node

@export var refresh : bool :
	set(value):
		sprite = self.get_parent().get_parent()
		player = self.get_parent()
		library_default = player.get_animation_library("")

		refresh_reset_anim()
		refresh_anims()

var sprite : AnimatedSprite2D
var player : AnimationPlayer
var library_default : AnimationLibrary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return

	sprite = self.get_parent().get_parent()
	player = self.get_parent()
	library_default = player.get_animation_library("")

	player.play.call_deferred("RESET")


var current_texture : Texture2D :
	get:
		return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)


func refresh_reset_anim() -> void:
	var anim_name := "RESET"
	var anim := get_or_create_anim(anim_name)
	anim.length = 0.0

	var sprite_track := get_and_clear_track(anim, ^".:sprite_frames")
	anim.track_insert_key(sprite_track, 0.0, sprite.sprite_frames)

	var name_track := get_and_clear_track(anim, ^".:animation")
	anim.track_insert_key(name_track, 0.0, sprite.animation)

	var frame_track := get_and_clear_track(anim, ^".:frame")
	anim.track_insert_key(frame_track, 0.0, 0)


func refresh_anims():
	for anim_name in sprite.sprite_frames.get_animation_names():
		var anim := get_or_create_anim(anim_name)

		var name_track := get_and_clear_track(anim, ^".:animation")
		anim.track_insert_key(name_track, 0.0, anim_name)

		var frame_track := get_and_clear_track(anim, ^".:frame")
		var speed := 1.0 / sprite.sprite_frames.get_animation_speed(anim_name)
		var cursor := 0.0
		for i in sprite.sprite_frames.get_frame_count(anim_name):
			anim.track_insert_key(frame_track, cursor, i)
			cursor += sprite.sprite_frames.get_frame_duration(anim_name, i) * speed

		anim.length = cursor
		if sprite.sprite_frames.get_animation_loop(anim_name):
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE


func get_or_create_anim(anim_name : StringName) -> Animation:
	var anim : Animation
	if player.has_animation(anim_name):
		anim = player.get_animation(anim_name)
	else:
		anim = Animation.new()
		library_default.add_animation(anim_name, anim)
	return anim


static func get_and_clear_track(anim: Animation, path: NodePath, type : int = Animation.TrackType.TYPE_VALUE, update : int = Animation.UpdateMode.UPDATE_DISCRETE) -> int:
	var track := anim.find_track(path, type)
	if track == -1:
		track = anim.add_track(type)
		anim.value_track_set_update_mode(track, update)
		anim.track_set_path(track, path)
	while anim.track_get_key_count(track) > 0:
		anim.track_remove_key(track, 0)
	return track
