
class_name DecoInvalid extends Deco


func _get_penny_tag_id() -> StringName:
	return StringName('invalid')


func _get_bbcode_tag_id() -> StringName:
	return StringName('')


func _get_requires_end_tag() -> bool:
	return false


func _get_bbcode_start_tag(inst: DecoInst) -> String:
	return inst.id


func _on_register_start(message: Message, tag: DecoInst) -> void:
	Penny.log_warn("Unrecognized tag %s" % tag)
