
## Displayable text_with_bbcode capable of producing decorations.
class_name Message extends RefCounted

static var INTERPOLATION_PATTERN := RegEx.create_from_string("(@([A-Za-z_]\\w*(?:\\.[A-Za-z_]\\w*)*)|\\[(.*?)\\])")
static var INTERJECTION_PATTERN := RegEx.create_from_string("(\\{.*?\\})")
static var DECO_TAG_PATTERN := RegEx.create_from_string("<(.*?)>")
static var DECO_SPAN_PATTERN := RegEx.create_from_string("(?s)<(.*?)>(.*)(?:<\\/>)")

static var DECO_START_TAG_PATTERN := RegEx.create_from_string("<>|<([^/].*?)>")
static var DECO_END_TAG_PATTERN := RegEx.create_from_string("$|<\\/>")

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

var decos : Array[DecoInst]


func _init(_raw: String, host: PennyHost) -> void:
	raw = _raw
	text_evaluated = raw

	## INTERJECTIONS

	## INTERPOLATION
	while true:
		var pattern_match := INTERPOLATION_PATTERN.search(text_evaluated)
		if not pattern_match: break

		var interp_expr_string := pattern_match.get_string(2) + pattern_match.get_string(3)	## ~= $2$3
		var inter_expr := Expr.from_tokens(PennyScript.parse_tokens_from_raw(interp_expr_string))
		var result = inter_expr.evaluate(host.data_root)
		var result_string : String
		if result is PennyObject:
			result_string = result.rich_name
		else:
			result_string = str(result)

		text_evaluated = sub_match(pattern_match, result_string)

	## FILTERS
	var filters : Array = host.data_root.get_value(PennyObject.FILTERS_KEY)
	for filter_path in filters:

		var filter : PennyObject = filter_path.evaluate(host.data_root)
		var pattern := RegEx.create_from_string(filter.get_value(PennyObject.FILTER_PATTERN_KEY))
		var replace : String = filter.get_value(PennyObject.FILTER_REPLACE_KEY)

		var start := 0
		while true:
			var pattern_match := pattern.search(text_evaluated, start)
			if not pattern_match: break

			var tag_match_found := false
			var tag_matches := DECO_TAG_PATTERN.search_all(text_evaluated, start)
			for tag_match in tag_matches:
				if pattern_match.get_start() >= tag_match.get_start() and pattern_match.get_start() < tag_match.get_end():
					start = tag_match.get_end()
					tag_match_found = true
					break
			if tag_match_found:
				continue

			text_evaluated = pattern.sub(text_evaluated, replace, false, start)
			start = pattern_match.get_start() + replace.length()

	## ESCAPES
	while true:
		var pattern_match := ESCAPE_PATTERN.search(text_evaluated)
		if not pattern_match: break

		if ESCAPE_SUBSITUTIONS.has(pattern_match.get_string(1)):
			text_evaluated = sub_match(pattern_match, ESCAPE_SUBSITUTIONS[pattern_match.get_string(1)])
		else:
			text_evaluated = sub_match(pattern_match, pattern_match.get_string(1))

	## TRANSLATE DECORATIONS TO BBCODE
	text_with_bbcode = "[p align=fill jst=w,k,sl]" + text_evaluated

	var tags_needing_end_stack : Array[int]
	var deco_stack : Array[DecoInst]
	while true:
		var tag_match := DECO_TAG_PATTERN.search(text_with_bbcode)
		if not tag_match: break
		if tag_match.get_string() == "</>":
			if not tags_needing_end_stack:
				text_with_bbcode = sub_match(tag_match, "")
				continue
			var start_tag_deco_count : int = tags_needing_end_stack.pop_back()
			var bbcode_end_tags_string := ""
			while start_tag_deco_count > 0:
				var deco : DecoInst = deco_stack.pop_back()
				deco.register_end(self, tag_match.get_start())
				bbcode_end_tags_string += deco.bbcode_tag_end
				start_tag_deco_count -= 1
			text_with_bbcode = sub_match(tag_match, bbcode_end_tags_string)
		else:
			var bbcode_start_tags_string := ""
			tags_needing_end_stack.push_back(0)
			var deco_strings := tag_match.get_string(1).split(",", false)
			for deco_string in deco_strings:
				var deco := DecoInst.new(deco_string)
				deco.register_start(self, tag_match.get_start())
				bbcode_start_tags_string += deco.bbcode_tag_start
				if deco.template.requires_end_tag:
					deco_stack.push_back(deco)
					tags_needing_end_stack.push_back(tags_needing_end_stack.pop_back() + 1)
			if tags_needing_end_stack.back() == 0:
				tags_needing_end_stack.pop_back()
			text_with_bbcode = sub_match(tag_match, bbcode_start_tags_string)
	while deco_stack:
		var deco : DecoInst = deco_stack.pop_back()
		deco.register_end(self, text_with_bbcode.length() - 1)
		text_with_bbcode += deco.bbcode_tag_end


static func sub_match(match: RegExMatch, sub: String) -> String:
	return match.subject.substr(0, match.get_start()) + sub + match.subject.substr(match.get_end(), match.subject.length() - match.get_end())


func _to_string() -> String:
	return text_with_bbcode


func append(_raw: String) -> void:
	text_with_bbcode += _raw
