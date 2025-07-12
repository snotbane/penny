
## An instance of a decoration. Exclusively bbcode tags will be processed and then removed.
class_name Tag extends RefCounted

enum {
	ARG_KEY = 1,
	ARG_VALUE = 2,
}

static var INSTANCE_PATTERN := RegEx.create_from_string(r"(?<!\\)<\s*([^<>]*?)\s*(?<!\\)>")
static var CONTENTS_PATTERN := RegEx.create_from_string(r"(^\s*\/\s*$)|(\w+)\s*\b(.*?)")
static var ID_PATTERN := RegEx.create_from_string(r"^\s*(\w*)")
static var ARG_PATTERN := RegEx.create_from_string(r"([^=\s]+)\s*=\s*([^=\s]+)")


var id : StringName
var args : Dictionary[StringName, Variant] = {}

var decoration : Decoration :
	get: return Decoration.from_id(id)

var open_index : int = -1
var close_index : int = -1

var owner : Typewriter
var open_remap : int = -1
var close_remap : int = -1

var is_typewriter_interfacing : bool :
	get: return true

var is_bbcode : bool :
	get: return decoration.is_bbcode if decoration else true

var is_closable : bool :
	get: return decoration.is_closable if decoration else true

var is_prod_stop : bool :
	get: return decoration.is_prod_stop if decoration else false

## Use meta to reduce array instancing.
var subtags : Array[Tag] :
	get: return get_meta(&"subtags") if has_meta(&"subtags") else []
	set(value): set_meta(&"subtags", value)

var bbcode_open : String :
	get: return decoration.get_bbcode_open(self) if decoration else get_bbcode_open()
func get_bbcode_open(_args: Dictionary[StringName, Variant] = args) -> String:
	if not is_bbcode: return ""

	var args_string := ""
	for k in _args.keys():
		var arg := variant_to_bbcode(_args[k])
		if k == id:
			args_string = "=%s" % [ arg ] + args_string
		else:
			args_string += " %s=%s" % [ k, arg ]
	return "[%s%s]" % [id, args_string]

var bbcode_close : String :
	get: return decoration.get_bbcode_close(self) if decoration else get_bbcode_close()
func get_bbcode_close() -> String:
	if not is_bbcode: return ""
	return "[/%s]" % id

func _to_string() -> String:
	return "<%s>" % id


static func new_from_string(contents: String, index: int, context: Cell) -> Tag:
	var result := Tag.new()

	var id_match := ID_PATTERN.search(contents)
	if id_match:
		result.id = ID_PATTERN.search(contents).get_string(1)
	else:
		printerr("Invalid id in tag contents: %s" % contents)

	var arg_matches := ARG_PATTERN.search_all(contents)
	for arg_match in arg_matches:
		var arg_key : StringName = arg_match.get_string(ARG_KEY)
		if result.args.has(arg_key):
			printerr("Tag argument '%s' already exists in the tag declaration. This will be ignored.")
			continue

		var expr := Expr.new_from_string(arg_match.get_string(ARG_VALUE))
		var arg_value : Variant = expr.evaluate(context)
		prints(arg_key, arg_value)
		if arg_value == null:
			printerr("Tag argument '%s' evaluated to null in string: `%s`." % [arg_key, contents])
			continue

		result.args[arg_key] = arg_value

	result.open_index = index
	if not result.is_closable: result.register_end()

	if result.decoration:
		result.decoration.register_on_creation(result)

	return result

static func new_from_other(other: Tag, id: StringName = other.id, args: Dictionary[StringName, Variant] = other.args) -> Tag:
	var result := Tag.new()

	result.id = id
	result.args = args
	result.open_index = other.open_index
	result.close_index = other.close_index

	return result


func register_end(index: int = open_index) -> void:
	close_index = index


func encounter_open(typewriter: Typewriter) -> void :
	if not decoration: return
	decoration.encounter_open(self, typewriter)
func encounter_close(typewriter: Typewriter) -> void :
	if not decoration: return
	decoration.encounter_close(self, typewriter)


func register(typewriter: Typewriter) -> void:
	owner = typewriter
	var original : String = typewriter.rtl.text
	open_remap = open_index
	close_remap = close_index
	for match in DisplayString.VISCHAR_PATTERN.search_all(original):
		var offset : int = DisplayString.VISCHAR_SUBSTITUTIONS.get(match.get_string(1), String()).length()
		if match.get_start() < open_index:
			open_remap -= match.get_end() - match.get_start() - offset
		if match.get_start() < close_index:
			close_remap -= match.get_end() - match.get_start() - offset

	if not decoration: return

	decoration.register_tag(self, typewriter)


static func variant_to_bbcode(value: Variant) -> String:
	if value is Color:
		return "#" + value.to_html()
	if value is Array or value is PackedStringArray:
		var result := ""
		for e in value:
			result += str(e) + ","
		return result.substr(0, result.length() - 1)
	return str(value)
