
extends Deco


func _get_id() -> String:
	return "size"


func _get_remapped_id() -> String:
	return "font_size"


func _modify_message(message: Message, tag: DecoInst) -> String:
	return direct_deco_to_bbcode_tag_with_single_argument(tag)


func _get_arguments() -> Dictionary : return {
	"pt": null
}
