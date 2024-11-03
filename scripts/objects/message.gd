
## Displayable text_with_bbcode capable of producing decorations.
class_name Message extends RefCounted

static var INTERPOLATION_PATTERN := RegEx.create_from_string("(@([A-Za-z_]\\w*(?:\\.[A-Za-z_]\\w*)*)|\\[(.*?)\\])")
static var INTERJECTION_PATTERN := RegEx.create_from_string("(\\{.*?\\})")
static var DECORATION_PATTERN := RegEx.create_from_string("(<.*?>)")
static var DECORATION_FULL_PATTERN := RegEx.create_from_string("(?s)<(.*?)>(.*?)(?:(?:<\\/(.*?)>)|$)")

static var ESCAPE_PATTERN := RegEx.create_from_string("\\\\(.)")
static var ESCAPE_SUBSITUTIONS := {
	"n": "\n",
	"t": "\t",
	"[": "[lb]",
	"]": "[rb]"
}

var raw : String
var text_evaluated : String
var text_with_bbcode : String


func _init(_raw: String, host: PennyHost) -> void:
	raw = _raw
	text_evaluated = raw

	## INTERJECTIONS

	## INTERPOLATION
	while true:
		var pattern_match := INTERPOLATION_PATTERN.search(text_evaluated)
		if pattern_match:
			var interp_expr_string := pattern_match.get_string(2) + pattern_match.get_string(3)	## ~= $2$3
			var inter_expr := Expr.from_tokens(PennyScript.parse_tokens_from_raw(interp_expr_string))
			var result = inter_expr.evaluate(host.data_root)
			var result_string : String
			if result is PennyObject:
				result_string = result.rich_name
			else:
				result_string = str(result)

			text_evaluated = substitute_entire_match(pattern_match, result_string)
			continue
		break

	## FILTERS
	var filters : Array = host.data_root.get_value(PennyObject.FILTERS_KEY)
	for filter_path in filters:
		var filter : PennyObject = filter_path.evaluate(host.data_root)
		var pattern := RegEx.create_from_string(filter.get_value(PennyObject.FILTER_PATTERN_KEY))
		var replace : String = filter.get_value(PennyObject.FILTER_REPLACE_KEY)
		text_evaluated = pattern.sub(text_evaluated, replace, true)

	## ESCAPES
	while true:
		var pattern_match := ESCAPE_PATTERN.search(text_evaluated)
		if pattern_match:
			if ESCAPE_SUBSITUTIONS.has(pattern_match.get_string(1)):
				text_evaluated = substitute_entire_match(pattern_match, ESCAPE_SUBSITUTIONS[pattern_match.get_string(1)])
			else:
				text_evaluated = substitute_entire_match(pattern_match, pattern_match.get_string(1))
			continue
		break

	# print("DECOS: %s" % Deco.REGISTRY)

	## TRANSLATE DECORATIONS TO BBCODE
	text_with_bbcode = text_evaluated
	while true:
		var pattern_match := DECORATION_FULL_PATTERN.search(text_with_bbcode)
		if pattern_match:
			var start_tag := pattern_match.get_string(1)
			var content := pattern_match.get_string(2)
			# var end_tag := pattern_match.get_string(3)

			var deco_method_from_id := Deco.get_method_by_id(start_tag)
			text_with_bbcode = substitute_entire_match(pattern_match, deco_method_from_id.call(self, start_tag, content))

			# if end_tag.is_empty():
			# 	end_tag = start_tag

			# if start_tag.is_empty():
			# 	text_with_bbcode = substitute_entire_match(pattern_match, "%s" % content)
			# else:
			# 	text_with_bbcode = substitute_entire_match(pattern_match, "[%s]%s[/%s]" % [start_tag, content, end_tag])
			# continue

		break

	text_with_bbcode = "[p align=fill jst=w,k,sl]" + text_with_bbcode


static func substitute_entire_match(match: RegExMatch, sub: String) -> String:
	return match.subject.substr(0, match.get_start()) + sub + match.subject.substr(match.get_end(), match.subject.length() - match.get_end())


func _to_string() -> String:
	return text_with_bbcode


func append(_raw: String) -> void:
	text_with_bbcode += _raw
