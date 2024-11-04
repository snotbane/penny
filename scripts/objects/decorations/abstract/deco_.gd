
class_name Deco extends Object

static var REGISTRY : Dictionary
const DECO_FILE_OMIT = [
	".godot",
	".vscode",
	".templates"
]


var requires_end_tag : bool :
	get: return _get_requires_end_tag()

var penny_tag_id : StringName :
	get: return _get_penny_tag_id()

var bbcode_tag_id : StringName :
	get: return _get_bbcode_tag_id()


static func _static_init() -> void:
	var deco_scripts := Utils.get_scripts_in_project("Deco", DECO_FILE_OMIT)
	for deco_script in deco_scripts:
		var deco : Deco = deco_script.new()
		Deco.REGISTRY[deco.penny_tag_id] = deco


static func get_method_by_id(tag_id: StringName) -> Deco:
	if REGISTRY.has(tag_id):
		return REGISTRY[tag_id]
	return REGISTRY[""]


## Whether or not this tag makes use of an end tag ("</>")
func _get_requires_end_tag() -> bool:
	return true


## Used to identify this tag when used in Penny code.
func _get_penny_tag_id() -> StringName:
	return StringName("_")


## The id of the tag used in bbcode. If the tag is not used in bbcode, return blank here (or extend [DecoEmpty])
func _get_bbcode_tag_id() -> StringName:
	return self.penny_tag_id


## What is actually written to the RichTextLabel in bbcode. Use [inst] to access arguments.
func _get_bbcode_start_tag(inst: DecoInst) -> String:
	return self.bbcode_tag_id


## Extra functionality used to modify the message data.
func _invoke(message: Message, tag: DecoInst) -> void:
	pass


