
class_name Text extends RefCounted

static var INTERJECTION_PATTERN := RegEx.create_from_string(r"(?<!\\)\{(.*?)(?<!\\)\}")
static var INTERPOLATION_PATTERN := RegEx.create_from_string(r"(?<!\\)@((?:\.?[A-Za-z_]\\w*)*)|(?<!\\)\[(.*?)(?<!\\)\]")
static var DECO_TAG_PATTERN := RegEx.create_from_string(r"(?<!\\)<(.*?)(?<!\\)>")
# static var DECO_SPAN_PATTERN := RegEx.create_from_string("(?s)<(.*?)>(.*)(?:<\\/>)")
static var ESCAPE_PATTERN := RegEx.create_from_string(r"\\(.)")
static var ESCAPE_SUBSITUTIONS := {
	"n": "\n",
	"t": "\t",
	"[": "[lb]",
	"]": "[rb]"
}

var context : Cell
var text : String

func _init(string: String = "") -> void:
	text = string


func _to_string() -> String:
	# return str(context) + ": " + text
	return text


static func sub_match(match: RegExMatch, sub: String) -> String:
	return match.subject.substr(0, match.get_start()) + sub + match.subject.substr(match.get_end(), match.subject.length() - match.get_end())
