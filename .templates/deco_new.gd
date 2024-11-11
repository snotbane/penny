
class_name DecoNew extends Deco

## REQUIRED: Call [register_instance] and pass in an instance of THIS script.
## REQUIRED: Ensure that this script is registered in a PennyDecoRegistry resource SOMEWHERE in the project.
static func _static_init() -> void:
	register_instance(DecoNew.new())


func _get_penny_tag_id() -> StringName:
	return StringName('id me')


func _get_bbcode_tag_id() -> StringName:
	return super._get_bbcode_tag_id()


func _get_bbcode_start_tag(inst: DecoInst) -> String:
	return super._get_bbcode_start_tag(inst)


func _on_register_start(message: Message, tag: DecoInst) -> void:
	pass
