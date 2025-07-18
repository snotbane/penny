
## Text that has been interpolated, filtered, decorated, etc., and is ready to be displayed.
class_name DisplayString extends RefCounted

const DECO_DELIMITER = ";"
static var INTERJECTION_PATTERN := RegEx.create_from_string(r"(?<!\\)\{(.*?)(?<!\\)\}")
static var INTERPOLATION_PATTERN := RegEx.create_from_string(r"(?<![\\=])(?:@((?:\.?[A-Za-z_]\w*)+)|\[(.*?)(?<!\\)\])")
static var DECO_TAG_PATTERN := RegEx.create_from_string(r"(?<!\\)<([^<>]*?)(?<!\\)>")
# static var DECO_SPAN_PATTERN := RegEx.create_from_string("(?s)<(.*?)>(.*)(?:<\\/>)")
static var ESCAPE_PATTERN := RegEx.create_from_string(r"\\(.)")
static var ESCAPE_SUBSITUTIONS : Dictionary[String, String] = {
	"\\": "\\",
	"n": "\n",
	"t": "\t",
	"[": "<lb>",
	"]": "<rb>",
}
static var VISCHAR_PATTERN := RegEx.create_from_string(r"\[(.*?)\]")
static var VISCHAR_SUBSTITUTIONS : Dictionary[String, String] = {
	"lb": "[",
	"rb": "]",
}
static var REGEX_WORD_COUNT := RegEx.create_from_string(r"\b[\w']+\b")
static var REGEX_LETTER_COUNT := RegEx.create_from_string(r"\w")

class Tag extends RefCounted:
	var element : DecorElement
	var is_start : bool
	func _init(_element: DecorElement, _is_start: bool) -> void:
		element = _element
		is_start = _is_start

# var text : String
var _text : String
var text : String :
	get: return _text
	set(value):
		if _text == value: return
		_text = value
		visible_text = get_visible_text(_text)
var visible_text : String

var elements : Array[DecorElement]
var tags : Array[Tag]

var interfacing_elements : Array[DecorElement] :
	get: return elements.filter( func(element: DecorElement) -> bool:
		return element.decor != null
		)

func _init(_text : String = "") -> void:
	text = _text


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			for element in elements:
				element.free()

func _to_string() -> String:
	return "`%s`" % text


func get_metrics() -> Dictionary:
	return {
		&"word_count":		REGEX_WORD_COUNT.search_all(self.text).size(),
		&"letter_count":	REGEX_LETTER_COUNT.search_all(self.text).size(),
	}


func compile_for_typewriter(tw: Typewriter) -> String:
	var result := text
	var offset := 0
	for tag in tags:
		var tag_index := (tag.element.open_index if tag.is_start else tag.element.close_index) + offset
		if tag.is_start:
			tag.element.compile_for_typewriter(tw)
		var tag_text := tag.element.bbcode_open if tag.is_start else tag.element.bbcode_close
		offset += tag_text.length()
		result = result.insert(tag_index, tag_text)
		# print("%s %s" % [tag.element.open_index if tag.is_start else tag.element.close_index, tag.element.bbcode_open if tag.is_start else tag.element.bbcode_close])
	return result


static func new_as_is(_text : String = "") -> DisplayString:
	return DisplayString.new(_text)


static func new_from_pure(pure: String = "", context := Cell.ROOT, filter_context := context) -> DisplayString:
	var result := pure

	if context != null:
		result = DisplayString.interpolate(result, context)
		result = DisplayString.filter_from_context(result, filter_context)

	return DisplayString.new_from_filtered(result, context)


static func new_from_filtered(string: String, context := Cell.ROOT) -> DisplayString:
	# print("Raw: `%s`" % string)

	var result := DisplayString.new(string)
	var unclosed_element_stack : Array[DecorElement]

	while true:
		var esc_match := ESCAPE_PATTERN.search(result.text)
		var element_match := DecorElement.INSTANCE_PATTERN.search(result.text)

		if not esc_match and not element_match: break

		if esc_match and (not element_match or esc_match.get_start() < element_match.get_start()):
			result.text = replace_match(esc_match, ESCAPE_SUBSITUTIONS.get(esc_match.get_string(1), esc_match.get_string(1)))
		elif element_match:
			if element_match.get_string(1) != "/":
				var element := DecorElement.new_from_string(element_match.get_string(1), element_match.get_start(), context)
				if element.closable: unclosed_element_stack.push_back(element)
				result.elements.push_back(element)
				result.tags.push_back(Tag.new(element, true))
			elif unclosed_element_stack:
				var element : DecorElement = unclosed_element_stack.pop_back()
				element.register_end(element_match.get_start())
				result.tags.push_back(Tag.new(element, false))
			result.text = replace_match(element_match, "")

	# print("Decorated: `%s`" % result.text)
	# print("Tags: %s" % str(result.elements))
	return result


static func interpolate(string: String, context: Cell) -> String:
	# print("interpolating: %s, context: %s" % [string, context])

	while true:
		var pattern_match : RegExMatch = INTERPOLATION_PATTERN.search(string)
		if not pattern_match: break
		# print("Found interpolation match: %s" % pattern_match.get_string())
		var interp_expr := Expr.new_from_string(pattern_match.get_string(1) + pattern_match.get_string(2))
		var evaluation := interp_expr.evaluate_adaptive(context)
		var interp_context : Cell = evaluation[&"context"]
		var interp_value : Variant = evaluation[&"value"]
		# print("Interp context: %s, value: %s" % [interp_context, interp_value])
		var interp_string : String
		if interp_value == null:
			interp_string = "NULL"
		elif interp_value is Cell:
			interp_context = interp_value
			interp_string = interp_value.key_text
			# print("Interp string: %s" % interp_string)
		elif interp_value is Color:
			interp_string = "#" + interp_value.to_html()
		else:
			interp_string = str(interp_value)

		string = replace_match(pattern_match, DisplayString.interpolate(interp_string, interp_context))

	# print("interpolation result: %s" % string)
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

		var elememt_match_found := false
		var element_matches := DECO_TAG_PATTERN.search_all(string, start)
		for element_match in element_matches:
			if pattern_match.get_start() > element_match.get_start() and pattern_match.get_start() <= element_match.get_end():
				start = element_match.get_end()
				elememt_match_found = true
				break
		if elememt_match_found: continue

		string = regex.sub(string, replace, false, start)
		start = pattern_match.get_start() + replace.length()
	return string


static func get_visible_text(string: String) -> String:
	var cursor := 0
	while cursor < string.length():
		var pattern_match := VISCHAR_PATTERN.search(string, cursor)
		if not pattern_match: break
		var substitution : String = VISCHAR_SUBSTITUTIONS.get(pattern_match.get_string(1), "")
		string = replace_match(pattern_match, substitution)
		cursor = pattern_match.get_start() + maxi(1, substitution.length())
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
