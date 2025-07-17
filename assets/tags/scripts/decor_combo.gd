class_name DecorCombo extends Decor

@export var ids : Array[StringName]

@export var subtags : Dictionary[StringName, Dictionary]


func populate(tag: Tag) -> void:
	var result : Array[Tag] = []
	for id in subtags.keys():
		var typed_args : Dictionary[StringName, Variant] = {}
		result.push_back(Tag.new_from_other(tag, id, typed_args.merged(subtags[id])))
	tag.subtags = result


func _get_bbcode_open(tag: Tag) -> String:
	var result := ""
	for subtag in tag.subtags:
		result += subtag.get_bbcode_open()
	return result

func _get_bbcode_close(tag: Tag) -> String:
	var result := ""
	for subtag in tag.subtags:
		result = subtag.get_bbcode_close() + result
	return result


func encounter_open(tag: Tag) -> void:
	for subtag in tag.subtags:
		subtag.encounter_open()

func encounter_close(tag: Tag) -> void:
	for subtag in tag.subtags:
		subtag.encounter_close()
