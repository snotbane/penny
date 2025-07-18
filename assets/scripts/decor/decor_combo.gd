class_name DecorCombo extends Decor

@export var ids : Array[StringName]

@export var subelements : Dictionary[StringName, Dictionary]


func populate(element: DecorElement) -> void:
	var result : Array[DecorElement] = []
	for _id in subelements.keys():
		var typed_args : Dictionary[StringName, Variant] = {}
		result.push_back(DecorElement.new_from_other(element, _id, typed_args.merged(subelements[_id])))
	element.subelements = result


func _get_bbcode_open(element: DecorElement) -> String:
	var result := ""
	for subelement in element.subelements:
		result += subelement.get_bbcode_open()
	return result

func _get_bbcode_close(element: DecorElement) -> String:
	var result := ""
	for subelement in element.subelements:
		result = subelement.get_bbcode_close() + result
	return result


func encounter_open(element: DecorElement) -> void:
	for subelement in element.subelements:
		subelement.encounter_open()

func encounter_close(element: DecorElement) -> void:
	for subelement in element.subelements:
		subelement.encounter_close()
