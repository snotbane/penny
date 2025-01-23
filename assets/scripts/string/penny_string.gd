
## Raw text as written in the Penny script. Strings in Penny are usually stored as this.
class_name PennyString extends Evaluable

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

func _init(string: String = "") -> void:
	text = string


func _to_string() -> String:
	return "`%s`" % text


func _evaluate(context: Cell) -> Variant:
	var result = text

	print("Evaluating PennyString ", self)

	## INTERPOLATION
	while true:
		var pattern_match := INTERPOLATION_PATTERN.search(result)
		if not pattern_match: break

		var interp_expr := Expr.new_from_string(pattern_match.get_string(1) + pattern_match.get_string(2))
		var evaluation := interp_expr.evaluate_adaptive(context)
		context = evaluation[&"context"]
		var interp : Variant = evaluation[&"value"]
		var interp_string : String
		if interp == null:
			interp_string = "NULL"
		elif interp is Cell:
			interp_string = interp.rich_name.text
		elif interp is Color:
			interp_string = "#" + interp.to_html()
		elif interp is PennyString:
			print("PennyString! ", interp)
		else:
			interp_string = str(interp)

		result = sub_match(pattern_match, interp_string)

	print("Evaluated PennyString `%s`" % result)
	return DisplayString.new(result)


static func sub_match(match: RegExMatch, sub: String) -> String:
	return match.subject.substr(0, match.get_start()) + sub + match.subject.substr(match.get_end(), match.subject.length() - match.get_end())
