
class_name DecoWait extends DecoMeta


func _get_is_span() -> bool:
	return false


# func _on_register_start(message: DecoratedText, inst: DecoInst) -> void:
# 	pass


# func _on_register_end(message: DecoratedText, inst: DecoInst) -> void:
# 	pass


func _on_encounter_start(typewriter: Typewriter, inst: DecoInst):
	await typewriter.wait()


# func _on_encounter_end(typewriter: Typewriter, inst: DecoInst) -> void:
# 	pass

