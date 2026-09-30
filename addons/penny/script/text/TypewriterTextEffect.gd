## A rich text effect that supports methods custom fx which depend on time.
@abstract
class_name TypewriterTextEffect
extends RichTextEffect

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if not (char_fx.env.has(&"_inst") and char_fx.env.has(&"_typewriter")):
		return false

	if char_fx.env._typewriter is not TypewriterTextLabel:
		return false

	var time_stamp : int = char_fx.env._typewriter.characters_time_stamps[char_fx.env._inst.owner.position + char_fx.relative_index]
	var visible_duration : float = float(char_fx.env._typewriter.time_elapsed_stamp - time_stamp) * 0.00_000_1

	return _process_custom_fx_typewriter(char_fx, char_fx.env._inst, char_fx.env._typewriter, visible_duration)


## Processes typewriter/time-dependent characters. [param visible_duration] is the amount of time that the character has been visible for.
@abstract
func _process_custom_fx_typewriter(char_fx: CharFXTransform, inst: PennyDecorationInstance, typewriter: TypewriterTextLabel, visible_duration: float) -> bool
