
## An actual instance of a [Deco] written out with specific arguments.
class_name DecoInst extends RefCounted

static var ID_PATTERN := RegEx.create_from_string("^\\s*(\\w+)")
static var ARG_PATTERN := RegEx.create_from_string("([^=\\s]+)\\s*=\\s*([^=\\s]+)")

var id : StringName
var args : Dictionary


var template : Deco :
	get: return Deco.get_method_by_id(id)


var bbcode_tag_start : String :
	get:
		if template.bbcode_tag_id.is_empty(): return String()
		return "[%s]" % template._get_bbcode_start_tag(self)

var bbcode_tag_end : String :
	get:
		if template.bbcode_tag_id.is_empty(): return String()
		return "[/%s]" % template.bbcode_tag_id


func _init(tag_string: String) -> void:
	id = ID_PATTERN.search(tag_string).get_string(1)
	var matches := ARG_PATTERN.search_all(tag_string)
	for match in matches:
		args[StringName(match.get_string(1))] = match.get_string(2)

func _to_string() -> String:
	var result := id
	for k in args.keys():
		result += " %s=%s" % [k, args[k]]
	return "<%s>" % result


func invoke(message: Message) -> void:
	template._invoke(message, self)


func get_argument(key: StringName) -> Variant:
	if not args.has(key):
		PennyException.new("Trying to access an argument that doesn't exist.").push()
		return "null"
	return args[key]

