
## An actual instance of a [Deco] written out with specific arguments.
class_name DecoInst extends RefCounted

static var ID_PATTERN := RegEx.create_from_string("^\\s*(\\w+)")
static var ARG_PATTERN := RegEx.create_from_string("([^=\\s]+)\\s*=\\s*([^=\\s]+)")

var id : StringName
var args : Dictionary

var template : Deco :
	get: return Deco.get_template_by_penny_id(id)


var bbcode_tag_start : String :
	get:
		if template.bbcode_tag_id.is_empty(): return String()
		return "[%s]" % template._get_bbcode_start_tag(self)

var bbcode_tag_end : String :
	get:
		if not template.requires_end_tag or template.bbcode_tag_id.is_empty(): return String()
		return "[/%s]" % template.bbcode_tag_id


func _init(string: String) -> void:
	var arg_matches := ARG_PATTERN.search_all(string)
	for arg_match in arg_matches:
		args[StringName(arg_match.get_string(1))] = arg_match.get_string(2)
	var id_match := ID_PATTERN.search(string)
	if id_match:
		id = id_match.get_string(1)
	else:
		id = args.keys()[0]


func _to_string() -> String:
	var result := id
	for k in args.keys():
		result += " %s=%s" % [k, args[k]]
	return "<%s>" % result


func register_start(message: Message) -> void:
	template._on_register_start(message, self)


func register_end(message: Message) -> void:
	template._on_register_end(message, self)


func get_argument(key: StringName) -> Variant:
	if not args.has(key):
		PennyException.new("Trying to access an argument that doesn't exist.").push()
		return "null"
	return args[key]

