
@tool class_name FlagController extends Node

signal flags_changed

@export var affected_sprites : Array[FlagSprite2D]

@export var arg : StringName
@export_tool_button("Push Flag") var push_flag_button := func() : push_flag(arg); arg = &""
@export_tool_button("Pull Flag") var pull_flag_button := func() : pull_flag(arg); arg = &""

var flags : PackedStringArray :
	get:
		var result := PackedStringArray()
		for sprite in affected_sprites:
			for flag in sprite.flags:
				if result.has(flag): continue
				result.push_back(flag)
		return result


func push_flag(flag: StringName) -> bool:
	var result := false
	for sprite in affected_sprites:
		result = sprite.add_flag(flag) or result
	if result: flags_changed.emit()
	return result


func pull_flag(flag: StringName) -> bool:
	var result := false
	for sprite in affected_sprites:
		result = sprite.remove_flag(flag) or result
	if result: flags_changed.emit()
	return result


## Applies the flags in reverse order. Ensures that flags at the front of the dictionary are applied with the highest priority.
func apply_flags_reverse(dict: Dictionary[StringName, bool]) -> bool:
	var result := false
	for sprite in affected_sprites:
		result = sprite.apply_flags_reverse(dict) or result
	if result: flags_changed.emit()
	return result


func set_talking_flag(value: bool) -> bool:
	return push_flag(get_talking_flag(value))


static func is_sprite_interruptible(sprite: AnimatedSprite2D) -> bool:
	return sprite.is_playing() and sprite.sprite_frames.get_animation_speed(sprite.animation) > 0.0

static func get_talking_flag(value: bool) -> StringName:
	return &"talk" if value else &"silent"
