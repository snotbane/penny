
## Displayable text_with_bbcode capable of producing decorations.
class_name Message extends RefCounted

static var INTERPOLATION_PATTERN := RegEx.create_from_string("(@([A-Za-z_]\\w*(?:\\.[A-Za-z_]\\w*)*)|\\[(.*?)\\])")
static var INTERJECTION_PATTERN := RegEx.create_from_string("(\\{.*?\\})")
static var DECO_TAG_PATTERN := RegEx.create_from_string("(<.*?>)")
static var DECO_SPAN_PATTERN := RegEx.create_from_string("(?s)<(.*?)>(.*)(?:<\\/>)")

static var DECO_START_TAG_PATTERN := RegEx.create_from_string("<>|<([^/].*?)>")
static var DECO_END_TAG_PATTERN := RegEx.create_from_string("(</>)|$")

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
		if not pattern_match: break

		var interp_expr_string := pattern_match.get_string(2) + pattern_match.get_string(3)	## ~= $2$3
		var inter_expr := Expr.from_tokens(PennyScript.parse_tokens_from_raw(interp_expr_string))
		var result = inter_expr.evaluate(host.data_root)
		var result_string : String
		if result is PennyObject:
			result_string = result.rich_name
		else:
			result_string = str(result)

		text_evaluated = substitute_entire_match(pattern_match, result_string)

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
			start = pattern_match.get_end()

	## ESCAPES
	while true:
		var pattern_match := ESCAPE_PATTERN.search(text_evaluated)
		if not pattern_match: break

		if ESCAPE_SUBSITUTIONS.has(pattern_match.get_string(1)):
			text_evaluated = substitute_entire_match(pattern_match, ESCAPE_SUBSITUTIONS[pattern_match.get_string(1)])
		else:
			text_evaluated = substitute_entire_match(pattern_match, pattern_match.get_string(1))

	## TRANSLATE DECORATIONS TO BBCODE
	text_with_bbcode = text_evaluated
	while true:
		var start_tag_match := DECO_START_TAG_PATTERN.search(text_with_bbcode)
		if not start_tag_match:
			DECO_END_TAG_PATTERN.sub(text_with_bbcode, "", true)
			break

		var bbcode_start_tag_string := ""
		var tags := start_tag_match.get_string(1).split(",", false)
		var decos_needing_end : Array[DecoInst]
		for tag in tags:
			var deco_inst := DecoInst.new(tag)
			if deco_inst.template.requires_end_tag:
				decos_needing_end.push_back(deco_inst)
			deco_inst.invoke(self)
			bbcode_start_tag_string += deco_inst.bbcode_tag_start
		text_with_bbcode = DECO_START_TAG_PATTERN.sub(text_with_bbcode, bbcode_start_tag_string)

		var bbcode_end_tag_string := ""
		decos_needing_end.reverse()
		for deco_inst in decos_needing_end:
			bbcode_end_tag_string += deco_inst.bbcode_tag_end

		var end_tag_match := get_start_tag_corresponding_end_tag_match(start_tag_match, text_with_bbcode)
		text_with_bbcode = substitute_entire_match(end_tag_match, bbcode_end_tag_string)

	text_with_bbcode = "[p align=fill jst=w,k,sl]" + text_with_bbcode


static func get_start_tag_corresponding_end_tag_match(start_tag_match: RegExMatch, source: String) -> RegExMatch:
	var remaining_start_tags := DECO_START_TAG_PATTERN.search_all(source, start_tag_match.get_end())
	var remaining_end_tags := DECO_END_TAG_PATTERN.search_all(source, start_tag_match.get_end())
	var diff := remaining_end_tags.size() - remaining_start_tags.size()
	return remaining_end_tags[remaining_end_tags.size() - (diff + 1)]


static func substitute_entire_match(match: RegExMatch, sub: String) -> String:
	return match.subject.substr(0, match.get_start()) + sub + match.subject.substr(match.get_end(), match.subject.length() - match.get_end())


func _to_string() -> String:
	return text_with_bbcode


func append(_raw: String) -> void:
	text_with_bbcode += _raw
