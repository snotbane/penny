## Text effect in which each character is aware of its global index and time since it appeared in a [Typewriter].
class_name TypewriterTextEffect extends RichTextEffect

const ENV_ELEMENT_ID := &"_elid"


func get_char_global_index(char_fx: CharFXTransform, element: DecorElement) -> int:
	return element.open_index + char_fx.relative_index


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if not char_fx.env.has(ENV_ELEMENT_ID): return false

	var element : DecorElement = instance_from_id(char_fx.env[ENV_ELEMENT_ID])
	var duration_visible := maxf(0.0, element.owner.time_elapsed - (element.owner.time_per_char[element.open_index + char_fx.relative_index]))
	return _process_custom_element_fx(
		char_fx,
		element,
		duration_visible
	)

## Processes when used in a [Typewriter].
## [param char_fx] is passed, unaltered, from [member _process_custom_fx].
## [param element] is the element to which the effect belongs, and also grants access to the [Typewriter] which is displaying this.
## [param time_visible] is the amount of time that this character has been visible for.
func _process_custom_element_fx(char_fx: CharFXTransform, element: DecorElement, duration_visible: float) -> bool:
	return true
