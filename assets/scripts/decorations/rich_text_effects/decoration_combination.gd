class_name DecorationCombination extends Decoration

@export var ids : Array[StringName]

# func _get_bbcode_open(tag: Tag) -> String:
# 	return tags.reduce( func(t, result) -> String:
# 		return result + t.get_bbcode_open(tag.args)
# 		, "")

# func _get_bbcode_close(tag: Tag) -> String:
# 	return tags.reduce( func(t, result) -> String:
# 		return t.get_bbcode_close() + result
# 		, "")


# func encounter_open(tag: Tag, typewriter: Typewriter) :
# 	for t in tags:
# 		await t.encounter_open(typewriter)

# func encounter_close(tag: Tag, typewriter: Typewriter) :
# 	for t in tags:
# 		await t.encounter_close(typewriter)
