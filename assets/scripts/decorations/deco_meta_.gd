
## Still holds span data, but doesn't create any bbcode tags.
class_name DecoMeta extends DecoSpan


# func _get_is_span() -> bool:
# 	return true


func _get_bbcode_tag_start(inst: DecoInst) -> String:
	return String()


func _get_bbcode_tag_end(inst: DecoInst) -> String:
	return String()


# func _on_register_start(message: DecoratedText, inst: DecoInst) -> void:
# 	pass


# func _on_register_end(message: DecoratedText, inst: DecoInst) -> void:
# 	pass


# func _on_encounter_start(typewriter: Typewriter, inst: DecoInst):
# 	pass


# func _on_encounter_end(typewriter: Typewriter, inst: DecoInst):
# 	pass

