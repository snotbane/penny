
class_name EscapedText extends Text


var escapes := {}

func _init(string: String) -> void:
	for match in ESCAPE_PATTERN.search_all(string):
		escapes[match.get_start()] = match.get_string()
		string = string.substr(0, match.get_start()) + string.substr(match.get_end())
	super._init(string)
