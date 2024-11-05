
extends Deco

func _get_penny_tag_id() -> StringName:
	return StringName('size')


func _get_bbcode_tag_id() -> StringName:
	return StringName('font_size')


func _get_bbcode_start_tag(inst: DecoInst) -> String:
	return "%s=%s" % [self.bbcode_tag_id, inst.get_argument('size')]
