
extends Deco


func _get_penny_tag_id() -> StringName:
	return StringName('')


func _get_bbcode_tag_id() -> StringName:
	return super._get_bbcode_tag_id()


func _get_bbcode_start_tag(inst: DecoInst) -> String:
	return super._get_bbcode_start_tag(inst)


func _on_register_start(message: Message, tag: DecoInst) -> void:
	pass
