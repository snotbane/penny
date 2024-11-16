
extends Deco


func _get_requires_end_tag() -> bool:
	return true


func _get_penny_tag_id() -> StringName:
	return StringName('speed')


func _get_bbcode_tag_id() -> StringName:
	return StringName('')


# func _get_bbcode_start_tag(inst: DecoInst) -> String:
# 	return super._get_bbcode_start_tag(inst)


# func _on_register_start(message: Message, tag: DecoInst) -> void:
# 	pass


# func _on_register_end(message: Message, tag: DecoInst) -> void:
# 	pass


func _on_encounter_start(typewriter: Typewriter, tag: DecoInst):
	typewriter.push_speed_tag(float(tag.args[StringName('speed')]))


func _on_encounter_end(typewriter: Typewriter, tag: DecoInst):
	typewriter.pop_speed_tag()

