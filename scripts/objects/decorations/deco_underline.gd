
extends Deco


static func _get_id() -> String:
	return "u"


static func _modify_message(message: Message, tag: String, content: String) -> String:
	return direct_deco_to_bbcode_tags(message, tag, content)
