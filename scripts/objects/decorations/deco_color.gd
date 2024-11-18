
extends Deco


func _get_penny_tag_id() -> StringName:
	return StringName('color')


# func _get_bbcode_tag_id() -> StringName:
# 	return super._get_bbcode_tag_id()


func _get_bbcode_start_tag(inst: DecoInst) -> String:
	return "%s=%s" % [self.bbcode_tag_id, inst.get_argument('color').to_html()]


# func _on_register_start(message: DisplayText, tag: DecoInst) -> void:
# 	pass


# func _on_register_end(message: DisplayText, tag: DecoInst) -> void:
# 	pass


# func _on_encounter_start(typewriter: Typewriter, tag: DecoInst):
# 	pass


# func _on_encounter_end(typewriter: Typewriter, tag: DecoInst):
# 	pass

