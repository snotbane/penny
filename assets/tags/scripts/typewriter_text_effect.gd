class_name TagTextEffect extends RichTextEffect

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if not char_fx.env.has(&"_tag"): return false

	var tag : Tag = instance_from_id(char_fx.env[&"_tag"])
	var time := tag.owner.time_per_char[tag.open_index + char_fx.relative_index]
	return _process_custom_tag_fx(char_fx, tag, tag.owner.time_elapsed - time)

## Processes when used in a [Typewriter].
## [time_visible] is the amount of time that this character has been visible for.
func _process_custom_tag_fx(char_fx: CharFXTransform, tag: Tag, time_visible: float) -> bool:
	return true
