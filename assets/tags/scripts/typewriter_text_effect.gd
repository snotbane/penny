class_name TypewriterTextEffect extends RichTextEffect

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if not char_fx.env.has(&"_tw"): return false

	var tw : Typewriter = instance_from_id(char_fx.env[&"_tw"])
	var time := tw.time_per_char[char_fx.env[&"_open"] + char_fx.relative_index]
	return _process_custom_typewriter_fx(char_fx, tw, tw.time_elapsed - time)

## Processes when used in a [Typewriter].
## [time_visible] is the amount of time that this character has been visible for.
func _process_custom_typewriter_fx(char_fx: CharFXTransform, tw: Typewriter, time_visible: float) -> bool:
	return true
