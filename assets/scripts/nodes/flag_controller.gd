
@tool
class_name FlagController extends Node

signal flags_changed

@export var affected_sprites : Array[AnimatedSprite2D]
## If enabled, animations will only be played when the frame has been updated or if not currently playing.
@export var await_frame_change_if_playing : bool = true

## A dictionary of [StringName] : [Array] containing [StringName]s. Defines all categories of each flag. When a flag is set, it will replace any/all other flags within the same category. Any [AnimatedSprite2D]s will play the animation with the most matching flags across ALL categories.
@export var flag_data : Dictionary

var _current_flags : Array[StringName]
@export var current_flags : Array[StringName] :
	get: return _current_flags
	set(value):
		if _current_flags == value: return
		_current_flags = value
		flags_changed.emit()

func _ready() -> void:
	flags_changed.connect(_flags_changed)
	_flags_changed()


func get_flag_category(flag: StringName) -> StringName:
	for k in flag_data.keys(): for e in flag_data[k]: if e == flag: return k
	return &""


func get_category_flags(category: StringName) -> Array:
	return flag_data[category]


func has_possible_flag(flag: StringName) -> bool:
	for k in flag_data.keys(): for i in flag_data[k]: if flag == i: return true
	return false


func has_current_flag(flag: StringName) -> bool:
	return current_flags.has(flag)


func set_current_flag(flag: StringName, play := true) -> void:
	if has_current_flag(flag) or not has_possible_flag(flag): return
	var category := get_flag_category(flag)
	for i in current_flags:
		if category == get_flag_category(i):
			current_flags.erase(i)
	current_flags.push_back(flag)

	if not play: return

	flags_changed.emit()


func _flags_changed() -> void:
	for sprite in affected_sprites:
		refresh_sprite(sprite)


func refresh_sprite(sprite: AnimatedSprite2D) -> void:
	var anim := get_animation_with_most_matching_flags(sprite.sprite_frames, current_flags)
	if anim == &"" or anim == sprite.animation or not sprite.sprite_frames.has_animation(anim): return
	if await_frame_change_if_playing and is_sprite_interruptible(sprite):
		await sprite.frame_changed
	sprite.animation = anim
	sprite.play()


static func is_sprite_interruptible(sprite: AnimatedSprite2D) -> bool:
	return sprite.is_playing() and sprite.sprite_frames.get_animation_speed(sprite.animation) > 0.0


func set_talking_flag(value: bool) -> void:
	set_current_flag(&"talk" if value else &"silent")


static func get_animation_with_most_matching_flags(frames: SpriteFrames, flags: PackedStringArray) -> StringName:
	var result : StringName = &""
	var length : int = 0
	for anim in frames.get_animation_names():
		var anim_flags := anim.split("_")
		var i_length := array_overlaps_count(flags, anim_flags)
		if i_length <= length: continue
		result = anim
		length = i_length
	return result


## Returns the number of items that both arrays share, assuming each does not contain any duplicates.
static func array_overlaps_count(a: Array, b: Array) -> int:
	var result : int = 0
	for i in a:
		for j in b:
			if i == j: result += 1; break
	return result
