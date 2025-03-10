
class_name DecoLock extends DecoMeta


func _get_is_span() -> bool:
	return true


# func _on_register_start(message: DisplayString, inst: DecoInst) -> void:
# 	pass


# func _on_register_end(message: DisplayString, inst: DecoInst) -> void:
# 	pass


func _on_encounter_start(typewriter: Typewriter, inst: DecoInst):
	typewriter.is_locked = true


func _on_encounter_end(typewriter: Typewriter, inst: DecoInst):
	typewriter.is_locked = false

