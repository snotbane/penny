
class_name DecoWait extends Deco

## REQUIRED: Call [register_instance] and pass in an instance of THIS script.
## REQUIRED: Ensure that this script is registered in a PennyDecoRegistry resource SOMEWHERE in the project.
static func _static_init() -> void:
	super._static_init()
	Deco.register_instance(DecoWait.new())


func _get_requires_end_tag() -> bool:
	return false


func _get_penny_tag_id() -> StringName:
	return StringName('wait')


func _get_bbcode_tag_id() -> StringName:
	return StringName('')


# func _get_bbcode_start_tag(inst: DecoInst) -> String:
# 	return super._get_bbcode_start_tag(inst)


# func _on_register_start(message: Message, tag: DecoInst) -> void:
# 	pass


# func _on_register_end(message: Message, tag: DecoInst) -> void:
# 	pass


func _on_encounter_start(typewriter: Typewriter, tag: DecoInst) -> void:
	typewriter.is_playing = false
	await typewriter.prodded
	typewriter.is_playing = true


# func _on_encounter_end(typewriter: Typewriter, tag: DecoInst) -> void:
# 	pass

