
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
	print(REGISTRY)


static func _get_id() -> String:
	return "_"


static func _modify_message(message: Message, tag: String, content: String) -> String:
	return content


static func direct_deco_to_bbcode_tags(message: Message, tag: String, content: String) -> String:
	return "[%s]%s[/%s]" % [tag, content, tag]


static func get_method_by_id(tag_id: String) -> Callable:
	if REGISTRY.has(tag_id):
		return REGISTRY[tag_id]
	return _modify_message
