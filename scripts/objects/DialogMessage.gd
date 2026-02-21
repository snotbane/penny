
class_name DialogMessage extends RefCounted

static var REGEX_DECLARATION_TYPE := RegEx.create_from_string(r"^([>+])\s*")
static var REGEX_LANGUAGE_SEPARATION := RegEx.create_from_string(r"\s*\[(.+?)\]\s*")

static var locale_fallback : String

static func _static_init() -> void:
	locale_fallback = ProjectSettings.get_setting("internationalization/locale/fallback")

enum {
	STANDARD,
	APPENDAGE,
}

var declaration_type : int
var translations : Dictionary # [String, DisplayString]

var context : Cell

func _init(raw_string: String = "") -> void:
	var m_declaration_type := REGEX_DECLARATION_TYPE.search(raw_string)

	assert(m_declaration_type != null, "No declaration type in DialogMessage: `%s`." % raw_string)

	match m_declaration_type.get_string(1):
		">": declaration_type = STANDARD
		"+": declaration_type = APPENDAGE

	var cursor : int = m_declaration_type.get_string().length()
	var tr_matches := REGEX_LANGUAGE_SEPARATION.search_all(raw_string, cursor)

	if tr_matches.is_empty():
		translations[""] = raw_string.substr(cursor)
	elif tr_matches[0].get_start() != cursor:
		translations[""] = raw_string.substr(cursor, tr_matches[0].get_start() - cursor)

	for i in tr_matches.size():
		cursor = tr_matches[i].get_end()
		var end := tr_matches[i+1].get_start() if i < tr_matches.size() - 1 else -1
		translations[tr_matches[i].get_string(1)] = raw_string.substr(cursor, end - cursor)

	for k in translations.keys():
		translations[k] = DisplayString.new_from_pure(translations[k])

	print("DialogMessage: ", translations)


func get_message_from_language(lang: String) -> DisplayString:
	return translations.get(OS.get_locale(), translations.get(OS.get_locale_language(), translations.get(locale_fallback, translations[&""])))


