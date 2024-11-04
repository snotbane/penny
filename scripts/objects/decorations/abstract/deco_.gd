
class_name Deco extends Object

static var REGISTRY : Dictionary
const DECO_FILE_OMIT = [
	".godot",
	".vscode",
	".templates"
]

static func _static_init() -> void:
	var deco_scripts := Utils.get_scripts_in_project("Deco", DECO_FILE_OMIT)
	for deco_script in deco_scripts:
		var deco : Deco = deco_script.new()
		Deco.REGISTRY[deco._get_id()] = deco._modify_message


func _get_id() -> String:
	return "_"


func _get_remapped_id() -> String:
	return self._get_id()


func _modify_message(message: Message, tag: DecoInst) -> String:
	return "%s"


func _get_is_self_closing() -> bool:
	return false


static func _keep_message(message: Message, tag: DecoInst) -> String:
	return "<%s>%s</%s>" % [tag, "%s", tag.id]


func _get_arguments() -> Dictionary : return {}


func direct_deco_to_bbcode_tags(tag: DecoInst) -> String:
	return "[%s]%s[/%s]" % [_get_remapped_id(), "%s", _get_remapped_id()]


func direct_deco_to_bbcode_tag_with_single_argument(tag: DecoInst) -> String:
	return "[%s=%s]%s[/%s]" % [_get_remapped_id(), tag.args[tag.args.keys()[0]], "%s", _get_remapped_id()]


static func get_method_by_id(tag_id: String) -> Callable:
	if REGISTRY.has(tag_id):
		return REGISTRY[tag_id]
	return _keep_message

