
class_name DecoDelay extends DecoMeta


func _get_is_span() -> bool:
	return false


# func _get_bbcode_start_tag(inst: DecoInst) -> String:
# 	return get_bbcode_start_tag_single_argument(inst)


# func _on_register_start(message: DisplayString, inst: DecoInst) -> void:
# 	pass


# func _on_register_end(message: DisplayString, inst: DecoInst) -> void:
# 	pass


func _on_encounter_start(typewriter: Typewriter, inst: DecoInst):
	await typewriter.delay(float(inst.get_argument(self.id)))


# func _on_encounter_end(typewriter: Typewriter, inst: DecoInst) -> void:
# 	pass

