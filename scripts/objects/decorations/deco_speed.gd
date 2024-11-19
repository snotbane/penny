
class_name DecoSpeed extends DecoMeta


func _get_is_span() -> bool:
	return true


# func _get_bbcode_start_tag(inst: DecoInst) -> String:
# 	return super._get_bbcode_start_tag(inst)


# func _on_register_start(message: DecoratedText, inst: DecoInst) -> void:
# 	pass


# func _on_register_end(message: DecoratedText, inst: DecoInst) -> void:
# 	pass


func _on_encounter_start(typewriter: Typewriter, inst: DecoInst):
	typewriter.push_speed_tag(float(inst.args[StringName('speed')]))


func _on_encounter_end(typewriter: Typewriter, inst: DecoInst):
	typewriter.pop_speed_tag()

