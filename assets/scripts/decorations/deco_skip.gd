
class_name DecoSkip extends DecoMeta


func _get_is_span() -> bool:
	return false


# func _get_bbcode_tag_start(inst: DecoInst) -> String:
# 	return super._get_bbcode_tag_start(inst)


# func _on_register_start(message: DisplayString, inst: DecoInst) -> void:
# 	pass


# func _on_register_end(message: DisplayString, inst: DecoInst) -> void:
# 	pass


func _on_encounter_start(typewriter: Typewriter, inst: DecoInst):
	pass
	# typewriter.dialog_node.advanced.emit.call_deferred


# func _on_encounter_end(typewriter: Typewriter, inst: DecoInst):
# 	pass

