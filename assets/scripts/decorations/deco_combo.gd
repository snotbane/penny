
## Combines multiple tags into one.
class_name DecoCombination extends Deco

@export var components : Array[Deco]


func _get_bbcode_tag_start(inst: DecoInst) -> String:
	var result := String()
	for component in components:
		result += component._get_bbcode_tag_start(inst)
	return result


func _get_bbcode_tag_end(inst: DecoInst) -> String:
	var result := String()
	for i in components.size():
		var component := components[components.size() - (i + 1)]
		result += component._get_bbcode_tag_end(inst)
	return result


func _on_register_start(message: DisplayString, inst: DecoInst) -> void:
	for component in components:
		component._on_register_start(message, inst)


func _on_register_end(message: DisplayString, inst: DecoInst) -> void:
	for i in components.size():
		var component := components[components.size() - (i + 1)]
		component._on_register_end(message, inst)


func _on_encounter_start(typewriter: Typewriter, inst: DecoInst):
	for component in components:
		await component._on_encounter_start(typewriter, inst)


func _on_encounter_end(typewriter: Typewriter, inst: DecoInst):
	for i in components.size():
		var component := components[components.size() - (i + 1)]
		await component._on_encounter_end(typewriter, inst)

