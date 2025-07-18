class_name DecorTextEffect extends RichTextEffect

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if not char_fx.env.has(&"_element"): return false

	var element : DecorElement = instance_from_id(char_fx.env[&"_element"])
	var time := element.owner.time_per_char[element.open_index + char_fx.relative_index]
	return _process_custom_element_fx(char_fx, element, element.owner.time_elapsed - time)

## Processes when used in a [Typewriter].
## [time_visible] is the amount of time that this character has been visible for.
func _process_custom_element_fx(char_fx: CharFXTransform, element: DecorElement, time_visible: float) -> bool:
	return true
