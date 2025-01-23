
## Mimics the decorations of an object's name_prefix key. The name_prefix must be an unclosed decoration.
class_name DecoLike extends DecoSpan

func _get_bbcode_tag_start(inst: DecoInst) -> String:
	var result := ""
	var context : Cell = inst.get_argument(&"like")
	var deco_insts := DisplayString.new(context.get_value(&"name_prefix")).decos
	for deco_inst in deco_insts:
		result += deco_inst.bbcode_tag_start
	return result

func _get_bbcode_tag_end(inst: DecoInst) -> String:
	var result := ""
	var context : Cell = inst.get_argument(&"like")
	var deco_insts := DisplayString.new(context.get_value(&"name_prefix")).decos
	for deco_inst in deco_insts:
		result = deco_inst.bbcode_tag_end + result
	return result