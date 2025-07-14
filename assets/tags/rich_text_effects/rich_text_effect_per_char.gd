class_name RichTextEffectPerChar extends RichTextEffect

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var tw := Typewriter.inst
	var time := tw.time_per_char[char_fx.env.get(&"_open", 0) + char_fx.relative_index]
	return _process_custom_fx_per_char(char_fx, tw.time_elapsed - time)
func _process_custom_fx_per_char(char_fx: CharFXTransform, relative_time: float) -> bool:
	return true
