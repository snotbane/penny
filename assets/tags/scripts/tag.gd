
## An instance of a decor. Exclusively bbcode tags will be processed and then removed.
class_name Tag extends Object

enum {
	ARG_KEY = 1,
	ARG_VALUE = 2,
}

enum {
	UNENCOUNTERED,
	OPENING,
	OPENED,
	CLOSING,
	CLOSED,
}

static var INSTANCE_PATTERN := RegEx.create_from_string(r"(?<!\\)<\s*([^<>]*?)\s*(?<!\\)>")
static var CONTENTS_PATTERN := RegEx.create_from_string(r"(^\s*\/\s*$)|(\w+)\s*\b(.*?)")
static var ID_PATTERN := RegEx.create_from_string(r"^\s*(\w*)")
static var ARG_PATTERN := RegEx.create_from_string(r"([^=\s]+)\s*=\s*([^=\s]+)")

var owner : Typewriter

var id : StringName
var args : Dictionary[StringName, Variant] = {}

var decor : Decor :
	get: return Decor.from_id(id)

var open_index : int = -1
var close_index : int = -1

var open_time : float = INF
var close_time : float = INF

var encounter_state : int = UNENCOUNTERED

var bbcode : bool :
	get: return decor.bbcode if decor else true

var closable : bool :
	get: return decor.closable if decor else true

var prod_stop : bool :
	get: return decor.prod_stop if decor else false

## Use meta to reduce array instancing.
var subtags : Array[Tag] :
	get: return get_meta(&"subtags") if has_meta(&"subtags") else []
	set(value): set_meta(&"subtags", value)

var bbcode_open : String :
	get: return decor.get_bbcode_open(self) if decor else get_bbcode_open()
func get_bbcode_open(_args: Dictionary[StringName, Variant] = args) -> String:
	if not bbcode: return ""

	var args_string := ""
	for k in _args.keys():
		var arg := variant_to_bbcode(_args[k])
		if k == id:
			args_string = "=%s" % [ arg ] + args_string
		else:
			args_string += " %s=%s" % [ k, arg ]
	return "[%s%s]" % [id, args_string]

var bbcode_close : String :
	get: return decor.get_bbcode_close(self) if decor else get_bbcode_close()
func get_bbcode_close() -> String:
	if not bbcode: return ""
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
	if not result.closable: result.register_end()

	if result.decor:
		result.decor.populate(result)

	return result

static func new_from_other(other: Tag, _id: StringName = other.id, _args: Dictionary[StringName, Variant] = other.args) -> Tag:
	var result := Tag.new()

	result.id = _id
	result.args = _args
	result.open_index = other.open_index
	result.close_index = other.close_index

	return result


func register_end(index: int = open_index) -> void:
	close_index = index


func compile_for_typewriter(tw: Typewriter) -> String:
	owner = tw
	if not decor: return ""
	return decor.compile_instance(self)


func encounter_open() :
	open_time = Typewriter.now
	encounter_state = OPENING
	if decor:
		await decor.encounter_open(self)
	encounter_state = OPENED if closable else CLOSED


func encounter_close() :
	close_time = Typewriter.now if close_time == INF else close_time
	encounter_state = CLOSING
	if decor:
		await decor.encounter_close(self)
	encounter_state = CLOSED


static func variant_to_bbcode(value: Variant) -> String:
	if value is Color:
		return "#" + value.to_html()
	if value is Array or value is PackedStringArray:
		var result := ""
		for e in value:
			result += str(e) + ","
		return result.substr(0, result.length() - 1)
	return str(value)
