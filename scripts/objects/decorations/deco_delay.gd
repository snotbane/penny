
class_name DecoDelay extends Deco

const DEFAULT_SECONDS := 0.667

## REQUIRED: Call [register_instance] and pass in an instance of THIS script.
## REQUIRED: Ensure that this script is registered in a PennyDecoRegistry resource SOMEWHERE in the project.
static func _static_init() -> void:
	register_instance(DecoDelay.new())


func _get_penny_tag_id() -> StringName:
	return StringName('delay')


func _get_bbcode_tag_id() -> StringName:
	return StringName('')


# func _get_bbcode_start_tag(inst: DecoInst) -> String:
# 	return ""


func _get_requires_end_tag() -> bool:
	return false


# func _on_register_start(message: Message, tag: DecoInst) -> void:
# 	pass


# func _on_register_end(message: Message, tag: DecoInst) -> void:
# 	pass


func _on_encounter_start(typewriter: Typewriter, tag: DecoInst) -> void:
	var delay_seconds := float(tag.args.get(StringName('seconds'), DEFAULT_SECONDS))

	typewriter.is_delayed = true
	await typewriter.get_tree().create_timer(delay_seconds).timeout
	typewriter.is_delayed = false


# func _on_encounter_end(typewriter: Typewriter, tag: DecoInst) -> void:
# 	pass

