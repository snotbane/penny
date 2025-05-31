
## Text that has been interpolated, filtered, decorated, etc., and is ready to be displayed.
class_name DisplayString extends RefCounted

const DECO_DELIMITER = ";"
static var INTERJECTION_PATTERN := RegEx.create_from_string(r"(?<!\\)\{(.*?)(?<!\\)\}")
static var INTERPOLATION_PATTERN := RegEx.create_from_string(r"(?<!\\)@((?:\.?[A-Za-z_]\w*)+)|s(?<!\\)\[(.*?)(?<!\\)\]")
static var DECO_TAG_PATTERN := RegEx.create_from_string(r"(?<!\\)<([^<>]*?)(?<!\\)>")
# static var DECO_SPAN_PATTERN := RegEx.create_from_string("(?s)<(.*?)>(.*)(?:<\\/>)")
static var ESCAPE_PATTERN := RegEx.create_from_string(r"\\(.)")
static var ESCAPE_SUBSITUTIONS : Dictionary[String, String] = {
	"n": "\n",
	"t": "\t",
	"[": "[lb]",
	"]": "[rb]"
}
static var REGEX_WORD_COUNT := RegEx.create_from_string(r"\b[\w']+\b")
static var REGEX_LETTER_COUNT := RegEx.create_from_string(r"\w")

var text : String
var decos : Array[DecoInst]

func _init(_text : String = "", _decos: Array[DecoInst] = []) -> void:
	text = _text
	decos = _decos


func _to_string() -> String:
	return "`%s`" % text


func get_metrics() -> Dictionary:
	return {
		&"word_count":		REGEX_WORD_COUNT.search_all(self.text).size(),
		&"letter_count":	REGEX_LETTER_COUNT.search_all(self.text).size(),
	}


static func new_as_is(_text : String = "") -> DisplayString:
	return DisplayString.new(_text)


static func new_from_pure(pure: String = "", context := Cell.ROOT, filter_context := context) -> DisplayString:
	var result := pure

	if context != null:
		result = DisplayString.interpolate(result, context)
		result = DisplayString.filter_from_context(result, filter_context)

	return DisplayString.new_from_filtered(result, context)


static func new_from_filtered(string: String, context := Cell.ROOT) -> DisplayString:
	var result := DisplayString.new()
	var tags_needing_end_stack : Array[int]
	var deco_stack : Array[DecoInst]
	while true:
		var tag_match := DECO_TAG_PATTERN.search(string)
		if not tag_match: break

		if tag_match.get_string() == "</>":
			if not tags_needing_end_stack:
				string = replace_match(tag_match, "")
				continue
			var start_tag_deco_count : int = tags_needing_end_stack.pop_back()
			var bbcode_end_tags_string := ""
			while start_tag_deco_count > 0:
				var deco : DecoInst = deco_stack.pop_back()
				deco.register_end(result, tag_match.get_start())
				bbcode_end_tags_string += deco.bbcode_tag_end
				start_tag_deco_count -= 1
			string = replace_match(tag_match, bbcode_end_tags_string)
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
			string = replace_match(tag_match, bbcode_start_tags_string)
	while deco_stack:
		var deco : DecoInst = deco_stack.pop_back()
		deco.register_end(result, string.length() - 1)

	string = DisplayString.escape(string)

	result.text = string

	return result


static func interpolate(string: String, context: Cell) -> String:
	# print("interpolating: %s, context: %s" % [string, context])
	while true:
		var pattern_match : RegExMatch = INTERPOLATION_PATTERN.search(string)
		if not pattern_match: break

		var interp_expr := Expr.new_from_string(pattern_match.get_string(1) + pattern_match.get_string(2))
		var evaluation := interp_expr.evaluate_adaptive(context)
		var interp_context : Cell = evaluation[&"context"]
		var interp_value : Variant = evaluation[&"value"]
		var interp_string : String
		if interp_value == null:
			interp_string = "NULL"
		elif interp_value is Cell:
			interp_context = interp_value
			interp_string = interp_value.text
		elif interp_value is Color:
			interp_string = "#" + interp_value.to_html()
		else:
			interp_string = str(interp_value)

		string = replace_match(pattern_match, DisplayString.interpolate(interp_string, interp_context))
	return string


static func filter_from_context(string: String, context: Cell) -> String:
	var filters : Array = context.get_value(Cell.K_FILTERS, [])
	for filter_ref in filters:
		var filter_cell : Cell = filter_ref.evaluate(context)
		string = DisplayString.filter(string, filter_cell.get_value(Cell.K_FILTER_PATTERN), filter_cell.get_value(Cell.K_FILTER_REPLACE))
	return string


static func filter(string: String, pattern: String, replace: String) -> String:
	var start := 0
	var regex := RegEx.create_from_string(pattern)
	while true:
		var pattern_match := regex.search(string, start)
		if not pattern_match: break

		var tag_match_found := false
		var tag_matches := DECO_TAG_PATTERN.search_all(string, start)
		for tag_match in tag_matches:
			if pattern_match.get_start() > tag_match.get_start() and pattern_match.get_start() <= tag_match.get_end():
				start = tag_match.get_end()
				tag_match_found = true
				break
		if tag_match_found: continue

		string = regex.sub(string, replace, false, start)
		start = pattern_match.get_start() + replace.length()
	return string


static func escape(string: String) -> String:
	while true:
		var pattern_match := ESCAPE_PATTERN.search(string)
		if not pattern_match: break
		if ESCAPE_SUBSITUTIONS.has(pattern_match.get_string(1)):
			string = replace_match(pattern_match, ESCAPE_SUBSITUTIONS[pattern_match.get_string(1)])
		else:
			string = replace_match(pattern_match, pattern_match.get_string(1))
	return string


static func replace_match(match: RegExMatch, sub: String) -> String:
	return match.subject.substr(0, match.get_start()) + sub + match.subject.substr(match.get_end(), match.subject.length() - match.get_end())


static func get_metrics_from_pure(pure: String) -> Dictionary:
	for match in DECO_TAG_PATTERN.search_all(pure):
		pure = replace_match(match, "")
	return {
		&"word_count":		REGEX_WORD_COUNT.search_all(pure).size(),
		&"letter_count":	REGEX_LETTER_COUNT.search_all(pure).size(),
	}
