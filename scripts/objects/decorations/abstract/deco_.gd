
class_name Deco extends Object

static var MASTER_REGISTRY : Dictionary

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


static func get_template_by_penny_id(penny_id: StringName) -> Deco:
	if MASTER_REGISTRY.has(penny_id):
		return MASTER_REGISTRY[penny_id]
	return MASTER_REGISTRY[StringName('invalid')]


static func register_instance(deco: Deco) -> void:
	Deco.MASTER_REGISTRY[deco.penny_tag_id] = deco


static func _get_instance_for_registry() -> Deco:
	return null


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
func _on_register_start(message: DecoratedText, tag: DecoInst) -> void:
	pass


func _on_register_end(message: DecoratedText, tag: DecoInst) -> void:
	pass


func _on_encounter_start(typewriter: Typewriter, tag: DecoInst):
	pass


func _on_encounter_end(typewriter: Typewriter, tag: DecoInst):
	pass


func get_bbcode_start_tag_single_argument(inst: DecoInst) -> String:
	return "%s=%s" % [self.bbcode_tag_id, inst.args[inst.args.keys()[0]]]

func get_bbcode_start_tag_all_arguments(inst: DecoInst) -> String:
	var result : String = self.bbcode_tag_id
	for k in inst.args.keys():
		result += " %s=%s" % [k, inst.args[k]]
	return result
