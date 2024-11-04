
extends Deco


func _get_id() -> String:
	return "i"


func _modify_message(message: Message, tag: DecoInst) -> String:
	return direct_deco_to_bbcode_tags(tag)
