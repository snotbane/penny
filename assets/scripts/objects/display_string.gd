
## Text that has been interpolated, filtered, decorated, etc., and is ready to be displayed.
class_name DisplayString extends RefCounted

const TAG_SPLITTER = ";"
static var INTERJECTION_PATTERN :=		RegEx.create_from_string(r"(?<!\\)\{(.*?)(?<!\\)\}")
static var INTERPOLATION_PATTERN :=		RegEx.create_from_string(r"(?<!\\)(?:@((?:\.?[A-Za-z_]\w*)+)|\[(.*?)(?<!\\)\])")
static var TAG_PATTERN :=				RegEx.create_from_string(r"(?<!\\)<\s*([^<>]*?)\s*(?<!\\)>")
static var ESCAPE_PATTERN := 			RegEx.create_from_string(r"\\(.)")
static var ESCAPE_SUBSITUTIONS : Dictionary[String, String] = {
	"\\": "\\",
	"n": "\n",
	"t": "\t",
	"[": "<lb>",
	"]": "<rb>",
}
static var VISCHAR_PATTERN :=			RegEx.create_from_string(r"\[(.*?)\]")
static var VISCHAR_SUBSTITUTIONS : Dictionary[String, String] = {
	"lb": "[",
	"rb": "]",
}
static var REGEX_WORD_COUNT :=			RegEx.create_from_string(r"\b[\w']+\b")
static var REGEX_LETTER_COUNT :=		RegEx.create_from_string(r"\w")


class Tag extends RefCounted:
	var elements : Array[DecorElement]
	var is_start : bool
	var closable : bool :
		get:
			for element in elements: if element.closable: return true
			return false


	func _init(_elements: Array[DecorElement], _is_start: bool) -> void:
		elements = _elements
		is_start = _is_start

class ConditionalBlock:
	var conditions : Array[DecorElement]

	var main_if_element : DecorElement :
		get: return conditions.front()

	func process(dstring: DisplayString) -> void:
		if not dstring.elements.has(main_if_element): return

		var start = 0
		var end = 0
		for i in conditions.size():
			match conditions[i].id:
				&"if":		if not conditions[i].args[&"if"]: continue
				&"elif":	if not conditions[i].args[&"elif"]: continue
				&"else":	pass
				_:			assert(false, "Unimplemented conditional: '%s'" % conditions[i].id)

			start = conditions[i].open_index
			end = conditions[i + 1].open_index if i != conditions.size() - 1 else main_if_element.close_index
			break

		dstring.erase(end, main_if_element.close_index)
		dstring.erase(main_if_element.open_index, start)


var free_elements_on_delete : bool = true

var _text : String
var text : String :
	get: return _text
	set(value):
		if _text == value: return
		_text = value
		# visible_text = get_visible_text(_text)
var visible_text : String

var elements : Array[DecorElement]
var tags : Array[Tag]

var interfacing_elements : Array[DecorElement] :
	get: return elements.filter( func(element: DecorElement) -> bool:
		return element.decor != null
		)

func _init(__text__ : String = "") -> void:
	text = __text__


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if free_elements_on_delete:	for element in elements:
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
	for tag in tags: for element in tag.elements:
		var tag_index := (element.open_index if tag.is_start else element.close_index) + offset
		if tag.is_start:
			element.compile_for_typewriter(tw)
		var tag_text := element.bbcode_open if tag.is_start else element.bbcode_close
		offset += tag_text.length()
		result = result.insert(tag_index, tag_text)
		# print("%s %s" % [element.open_index if tag.is_start else element.close_index, element.bbcode_open if tag.is_start else element.bbcode_close])
	return result


## Erases a portion of this [DisplayString], and re-indexes [DecorElement]s.
func erase(start: int = 0, end: int = -1, remove_elements: bool = true) -> void:
	if start == end: return
	# if end == -1: end = text.length()

	text = text.substr(0, start) + text.substr(end)

	for element in elements:
		if element.open_index > start:
			element.open_index = maxi(element.open_index - (end - start), start)
		if element.close_index > start:
			element.close_index = maxi(element.close_index - (end - start), start)


static func new_as_is(__text__ : String = "") -> DisplayString:
	var result := DisplayString.new(__text__)

	result.visible_text = DisplayString.get_visible_text(result.text)
	return result


static func new_from_pure(pure: String = "", context := Cell.ROOT, filter_context := context) -> DisplayString:
	var result := pure

	if context != null:
		result = DisplayString.interpolate(result, context)
		result = DisplayString.filter_from_context(result, filter_context)

	return DisplayString.new_from_filtered(result, context)


static func new_from_filtered(string: String, context := Cell.ROOT) -> DisplayString:
	# print("Raw: `%s`" % string)

	var result := DisplayString.new(string)
	var unclosed_tag_stack : Array[Tag]
	var if_block_list : Array[ConditionalBlock]
	var if_block_stack : Array[ConditionalBlock]

	while true:
		var esc_match := ESCAPE_PATTERN.search(result.text)
		var tag_match := TAG_PATTERN.search(result.text)

		if not esc_match and not tag_match: break

		if esc_match and (not tag_match or esc_match.get_start() < tag_match.get_start()):
			result.text = replace_match(esc_match, ESCAPE_SUBSITUTIONS.get(esc_match.get_string(1), esc_match.get_string(1)))
		elif tag_match:
			if tag_match.get_string(1) != "/":
				var tag_elements : Array[DecorElement]
				for element_string in tag_match.get_string(1).split(TAG_SPLITTER, false):
					var element := DecorElement.new_from_string(element_string, tag_match.get_start(), context)
					tag_elements.push_back(element)
					result.elements.push_back(element)

					match element.id:
						&"if", &"elif", &"else":
							if element.id == &"if":
								if_block_stack.push_back(ConditionalBlock.new())
							assert(not if_block_stack.is_empty())
							if_block_stack.back().conditions.push_back(element)
				var tag := Tag.new(tag_elements, true)
				if tag.closable: unclosed_tag_stack.push_back(tag)
				result.tags.push_back(tag)
			elif unclosed_tag_stack:
				var tag : Tag = unclosed_tag_stack.pop_back()
				for element in tag.elements:
					element.register_end(tag_match.get_start())
					match element.id:
						&"if":
							if_block_list.push_back(if_block_stack.pop_back())
				var end_elements := tag.elements.duplicate()
				end_elements.reverse()
				result.tags.push_back(Tag.new(end_elements, false))
			result.text = replace_match(tag_match, "")

	while if_block_stack: if_block_list.push_back(if_block_stack.pop_back())
	for block in if_block_list: block.process(result)

	# print("Decorated: `%s`" % result.text)
	# print("Elements: %s" % str(result.elements))

	result.visible_text = DisplayString.get_visible_text(result.text)
	return result


static func interpolate(string: String, context: Cell) -> String:
	# print("interpolating: %s, context: %s" % [string, context])

	while true:
		var pattern_match : RegExMatch = INTERPOLATION_PATTERN.search(string)
		if not pattern_match: break
		# print("Found interpolation match: %s" % pattern_match.get_string())
		var interp_data := pattern_match.get_string(1) + pattern_match.get_string(2)
		var interp_expr := Expr.new_from_string(interp_data)
		var evaluation := interp_expr.evaluate_adaptive(context)
		var interp_context : Cell = evaluation[&"context"]
		var interp_value : Variant = evaluation[&"value"]
		# print("Interp context: %s, value: %s" % [interp_context, interp_value])
		var interp_string : String
		if interp_value == null:
			interp_string = "\\@%s" % interp_data
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
		var element_matches := TAG_PATTERN.search_all(string, start)
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
	for match in TAG_PATTERN.search_all(pure):
		pure = replace_match(match, "")
	return {
		&"word_count":		REGEX_WORD_COUNT.search_all(pure).size(),
		&"letter_count":	REGEX_LETTER_COUNT.search_all(pure).size(),
	}
