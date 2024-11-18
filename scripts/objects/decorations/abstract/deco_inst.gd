
## An actual instance of a [Deco] written out with specific arguments.
class_name DecoInst extends RefCounted

static var ID_PATTERN := RegEx.create_from_string("^\\s*(\\w+)")
static var ARG_PATTERN := RegEx.create_from_string("([^=\\s]+)\\s*=\\s*([^=\\s]+)")
static var STRIP_BBCODE_PATTERN := RegEx.create_from_string("\\[.+?\\]")

var id : StringName
var args : Dictionary

var start_index : int
var end_index : int = -1

var start_remapped : int
var end_remapped : int

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


func _init(string: String, context: PennyObject) -> void:
	var arg_matches := ARG_PATTERN.search_all(string)
	for arg_match in arg_matches:
		var expr := Expr.from_string(arg_match.get_string(2))
		var bind : Variant = expr.evaluate(context)
		if bind != null:
			args[StringName(arg_match.get_string(1))] = bind
		else:
			PennyException.new("deco argument '%s' evaluated to null." % arg_match.get_string(1)).push()

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


func register_start(message: DecoratedText, index: int) -> void:
	message.decos.push_back(self)
	start_index = index
	template._on_register_start(message, self)


func register_end(message: DecoratedText, index: int) -> void:
	end_index = index
	template._on_register_end(message, self)


func encounter_start(typewriter: Typewriter) -> void:
	await self.template._on_encounter_start(typewriter, self)


func encounter_end(typewriter: Typewriter) -> void:
	await self.template._on_encounter_end(typewriter, self)


func get_argument(key: StringName) -> Variant:
	if not args.has(key):
		PennyException.new("Trying to access an argument '%s' that doesn't exist." % key).push()
		return "null"
	if args[key] == null:
		PennyException.new("The argument '%s' has a null value." % key).push()
	return args[key]


func create_remap_for(typewriter: Typewriter) -> void:
	var original : String = typewriter.rtl.text

	start_remapped = start_index
	end_remapped = end_index
	for strip_match in STRIP_BBCODE_PATTERN.search_all(original):
		if strip_match.get_start() < start_index:
			start_remapped -= strip_match.get_end() - strip_match.get_start()
		if strip_match.get_start() < end_index:
			end_remapped -= strip_match.get_end() - strip_match.get_start()
