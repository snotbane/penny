
## Mimics the decorations of an object's name_prefix key. The name_prefix must be an unclosed decoration.
class_name DecoLike extends DecoSpan

func _get_bbcode_tag_start(inst: DecoInst) -> String:
	var result := ""
	var context : PennyObject = inst.get_argument(&"like")
	var deco_insts := DecoratedText.from_raw(context.get_value(PennyObject.NAME_PREFIX_KEY), context).decos
	for deco_inst in deco_insts:
		result += deco_inst.bbcode_tag_start
	return result

func _get_bbcode_tag_end(inst: DecoInst) -> String:
	var result := ""
	var context : PennyObject = inst.get_argument(&"like")
	var deco_insts := DecoratedText.from_raw(context.get_value(PennyObject.NAME_PREFIX_KEY), context).decos
	for deco_inst in deco_insts:
		result = deco_inst.bbcode_tag_end + result
	return result