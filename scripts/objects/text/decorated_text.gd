
## Displayable text capable of producing decorations.
class_name DecoratedText extends Text

# static var DECO_START_TAG_PATTERN := RegEx.create_from_string("(?<!\\\\)<>|[^\\\\]?<([^/].*[^\\\\])>")
# static var DECO_END_TAG_PATTERN := RegEx.create_from_string("<\\/>|(?<!<\\/>)$")
const DECO_DELIMITER = ";"

var decos : Array[DecoInst]


static func from_filtered(filtered: FilteredText, context := PennyObject.STATIC_ROOT) -> DecoratedText:
	var result := DecoratedText.new()
	var result_text := filtered.text

	var tags_needing_end_stack : Array[int]
	var deco_stack : Array[DecoInst]
	while true:
		var tag_match := DECO_TAG_PATTERN.search(result_text)
		if not tag_match: break
		if tag_match.get_string() == "</>":
			if not tags_needing_end_stack:
				result_text = sub_match(tag_match, "")
				continue
			var start_tag_deco_count : int = tags_needing_end_stack.pop_back()
			var bbcode_end_tags_string := ""
			while start_tag_deco_count > 0:
				var deco : DecoInst = deco_stack.pop_back()
				deco.register_end(result, tag_match.get_start())
				bbcode_end_tags_string += deco.bbcode_tag_end
				start_tag_deco_count -= 1
			result_text = sub_match(tag_match, bbcode_end_tags_string)
		else:
			var bbcode_start_tags_string := ""
			tags_needing_end_stack.push_back(0)
			var deco_strings := tag_match.get_string(1).split(DECO_DELIMITER, false)
			for deco_string in deco_strings:
				var deco := DecoInst.new(deco_string, context)
				result.decos.push_back(deco)
				deco.register_start(result, tag_match.get_start())
				bbcode_start_tags_string += deco.bbcode_tag_start
				if deco.template and deco.template.is_span:
					deco_stack.push_back(deco)
					tags_needing_end_stack.push_back(tags_needing_end_stack.pop_back() + 1)
			if tags_needing_end_stack.back() == 0:
				tags_needing_end_stack.pop_back()
			result_text = sub_match(tag_match, bbcode_start_tags_string)
	while deco_stack:
		var deco : DecoInst = deco_stack.pop_back()
		deco.register_end(result, result_text.length() - 1)

	## ESCAPES
	while true:
		var pattern_match := Text.ESCAPE_PATTERN.search(result_text)
		if not pattern_match: break
		if ESCAPE_SUBSITUTIONS.has(pattern_match.get_string(1)):
			result_text = sub_match(pattern_match, ESCAPE_SUBSITUTIONS[pattern_match.get_string(1)])
		else:
			result_text = sub_match(pattern_match, pattern_match.get_string(1))

	result.text = result_text
	return result


static func from_raw(raw: String, context := PennyObject.STATIC_ROOT) -> DecoratedText:
	var filtered := FilteredText.from_raw(raw, context)
	return DecoratedText.from_filtered(filtered, context)
