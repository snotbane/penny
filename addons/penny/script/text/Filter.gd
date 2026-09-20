## Representation of a filter used to enhance rich text.
@tool
extends Resource


@export_multiline
var pattern: String:
	get: return regex.get_pattern()
	set(value): regex.compile(value)


@export
var replace: Variant


var regex : RegEx


var is_valid : bool:
	get: return not pattern.is_empty() and regex.is_valid()


func _init(__pattern__ = null, __replace__ = null) -> void:
	regex = RegEx.new()

	if __pattern__ is String:
		pattern = __pattern__

	elif __pattern__ is Penny.Message:
		pattern = __pattern__.translation_default

	replace = __replace__


func _to_string() -> String:
	return "r\"%s\" -> %s (filter)" % [
		pattern,
		replace
	]


func process(string: String, translation: StringName = &"") -> String:
	if not is_valid:
		printerr("Filter pattern '%s' is not valid." % pattern)
		return string

	assert(replace is String, "For now, replace must be a raw String. (%s)" % replace)

	var replace_string : String
	replace_string = str(replace)

	var result := string
	var start := 0
	while true:
		var m := regex.search(result, start)
		if not m:
			break

		var m_is_inside_tag := false
		var tag_matches := PennyScript.MessageParser.REGEX_DECORATE_TAG.search_all(result, start)
		for m_tag in tag_matches:
			if m.get_start() > m_tag.get_start() and m.get_end() <= m_tag.get_end():
				m_is_inside_tag = true
				start = m_tag.get_end()
				break
		if m_is_inside_tag:
			continue

		result = PennyScript.MessageParser.regex_replace_match(m, replace_string)
		start = m.get_start() + replace_string.length()

	return result
