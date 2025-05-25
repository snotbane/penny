
## An [AnimatedSprite2D] that can change its animation by adding or removing [StringName] flags to it.
@tool class_name FlagSprite2D extends AnimatedSprite2D

const DELIMITER : String = "_"

var flags : PackedStringArray :
	get: return FlagSprite2D.get_string_flags(self.animation)
	set(value): _set_flags(value)
func _set_flags(array: PackedStringArray) -> void:
	var candidates := self.sprite_frames.get_animation_names()
	for flag in array:
		var filter := PackedStringArray()
		for anim in candidates: if FlagSprite2D.get_string_flags(anim).has(flag): filter.push_back(anim)
		match filter.size():
			0: continue
			1: self.animation = filter[0]; return
		candidates = filter.duplicate()
	match candidates.size():
		0: printerr("FlagSprite2D %s: Attempted to apply flags %s, but no matching animations were found." % [ self, array ])
		_: printerr("FlagSprite2D %s: While applying flags %s, multiple animations were found %s" % [ self, array, candidates ])


func add_flag(flag: StringName) -> void:
	if flags.has(flag): print("Warning: Flag '%s' already exists in animation '%s'" % [flag, self.animation]); return
	var query := flags
	query.insert(0, flag)
	_set_flags(query)


func remove_flag(flag: StringName) -> void:
	var i := flags.find(flag)
	if i == -1: print("Warning: Attempted to remove flag '%s' on sprite %s, but this flag does not exist in the current animation '%s'" % [ flag, self, self.animation ]); return
	var query := flags
	query.remove_at(i)
	_set_flags(query)


static func get_string_flags(s: StringName) -> PackedStringArray:
	return s.split(DELIMITER, false)
