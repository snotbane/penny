
class_name DecoDelay extends Deco

const DEFAULT_SECONDS := 0.667


func _get_requires_end_tag() -> bool:
	return false


func _get_penny_tag_id() -> StringName:
	return StringName('delay')


func _get_bbcode_tag_id() -> StringName:
	return StringName('')


# func _get_bbcode_start_tag(inst: DecoInst) -> String:
# 	return ""


# func _on_register_start(message: Message, tag: DecoInst) -> void:
# 	pass


# func _on_register_end(message: Message, tag: DecoInst) -> void:
# 	pass


func _on_encounter_start(typewriter: Typewriter, tag: DecoInst):
	await typewriter.delay(float(tag.args.get(StringName('seconds'), DEFAULT_SECONDS)))


# func _on_encounter_end(typewriter: Typewriter, tag: DecoInst) -> void:
# 	pass

