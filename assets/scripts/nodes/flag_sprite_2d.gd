
## An [AnimatedSprite2D] that can change its animation by adding or removing [StringName] flags to it.
@tool class_name FlagSprite2D extends AnimatedSprite2D

const DELIMITER : String = "_"

var animation_loop : bool :
	get: return self.sprite_frames.get_animation_loop(self.animation)

var flags : PackedStringArray :
	get: return FlagSprite2D.get_string_flags(self.animation)
	set(value): set_flags(value)
func set_flags(array: PackedStringArray) -> bool:
	var candidates := self.sprite_frames.get_animation_names()
	for flag in array:
		var filter := PackedStringArray()
		for anim in candidates: if FlagSprite2D.get_string_flags(anim).has(flag): filter.push_back(anim)
		match filter.size():
			0: continue
			1:
				if self.animation != filter[0]: self.play(filter[0])
				return true
		candidates = filter.duplicate()

	match candidates.size():
		0: printerr("FlagSprite2D %s: Attempted to apply flags %s, but no matching animations were found." % [ self, array ])
		_: printerr("FlagSprite2D %s: While applying flags %s, multiple animations were found %s" % [ self, array, candidates ])
	return false


var all_possible_flags : PackedStringArray :
	get:
		var result := PackedStringArray()
		for anim in sprite_frames.get_animation_names():
			for flag in FlagSprite2D.get_string_flags(anim):
				if result.has(flag): continue
				result.push_back(flag)
		return result


func add_flag(flag: StringName) -> bool:
	if flags.has(flag): print("Warning: Flag '%s' already exists in animation '%s'" % [flag, self.animation]); return false
	var query := flags
	query.insert(0, flag)
	return set_flags(query)


func remove_flag(flag: StringName) -> bool:
	var i := flags.find(flag)
	if i == -1: print("Warning: Attempted to remove flag '%s' on sprite %s, but this flag does not exist in the current animation '%s'" % [ flag, self, self.animation ]); return false
	var query := flags
	query.remove_at(i)
	return set_flags(query)


## Applies the flags in reverse order. Ensures that flags at the front of the dictionary are applied with the highest priority.
func apply_flags_reverse(dict: Dictionary[StringName, bool]) -> bool:
	var result := false
	var keys := dict.keys()
	for i in keys.size():
		var flag : StringName = keys[-i-1]
		if dict[flag]:	result = result or add_flag(flag)
		else:			result = result or remove_flag(flag)
	return result


static func get_string_flags(s: StringName) -> PackedStringArray:
	return s.split(DELIMITER, false)
