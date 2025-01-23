
## Text that has been interpolated, filtered, decorated, etc., and is ready to be displayed.
class_name DisplayString extends RefCounted

static var INTERJECTION_PATTERN := RegEx.create_from_string(r"(?<!\\)\{(.*?)(?<!\\)\}")
static var INTERPOLATION_PATTERN := RegEx.create_from_string(r"(?<!\\)@((?:\.?[A-Za-z_]\w*)+)|(?<!\\)\[(.*?)(?<!\\)\]")
static var DECO_TAG_PATTERN := RegEx.create_from_string(r"(?<!\\)<(.*?)(?<!\\)>")
# static var DECO_SPAN_PATTERN := RegEx.create_from_string("(?s)<(.*?)>(.*)(?:<\\/>)")
static var ESCAPE_PATTERN := RegEx.create_from_string(r"\\(.)")
static var ESCAPE_SUBSITUTIONS := {
	"n": "\n",
	"t": "\t",
	"[": "[lb]",
	"]": "[rb]"
}

var text : String
var decos : Array[DecoInst]

func _init(_text : String = "", _decos: Array[DecoInst] = []) -> void:
	text = _text
	decos = _decos


func _to_string() -> String:
	return "`%s`" % text


static func new_pure(_text : String = "") -> DisplayString:
	return DisplayString.new(_text)


static func new_rich(pure: String = "", context := Cell.ROOT) -> DisplayString:
	var result := pure

	result = DisplayString.interpolate(result, context)

	return DisplayString.new(result)


static func interpolate(string: String, context: Cell) -> String:
	while true:
		var pattern_match : RegExMatch = INTERPOLATION_PATTERN.search(string)
		if not pattern_match: break

		var interp_expr := Expr.new_from_string(pattern_match.get_string(1) + pattern_match.get_string(2))
		var evaluation := interp_expr.evaluate_adaptive(context)
		var interp : Variant = evaluation[&"value"]
		var interp_string : String
		if interp == null:
			interp_string = "NULL"
		elif interp is Cell:
			interp_string = interp.rich_name
		elif interp is Color:
			interp_string = "#" + interp.to_html()
		else:
			interp_string = str(interp)

		string = replace_match(pattern_match, interpolate(interp_string, evaluation[&"context"]))
	return string


static func replace_match(match: RegExMatch, sub: String) -> String:
	return match.subject.substr(0, match.get_start()) + sub + match.subject.substr(match.get_end(), match.subject.length() - match.get_end())
