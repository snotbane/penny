
class_name DecoSize extends Deco

## REQUIRED: Call [register_instance] and pass in an instance of THIS script.
## REQUIRED: Ensure that this script is registered in a PennyDecoRegistry resource SOMEWHERE in the project.
static func _static_init() -> void:
	register_instance(DecoSize.new())


func _get_penny_tag_id() -> StringName:
	return StringName('size')


func _get_bbcode_tag_id() -> StringName:
	return StringName('font_size')


func _get_bbcode_start_tag(inst: DecoInst) -> String:
	return "%s=%s" % [self.bbcode_tag_id, inst.get_argument('size')]
