## Contains multiple translations for a single dialog block declaration. [DialogMessage]s will change only when scripts are reloaded. Strings within are prepared to be turned into [DialogMessageSnapshot]s.
class_name DialogMessage extends RefCounted

static var REGEX_DECLARATION_TYPE := RegEx.create_from_string(r"^[>+]\s*")
static var REGEX_MERGE_LINES := RegEx.create_from_string(r"\s*\n\s*")
static var REGEX_LANGUAGE_SEPARATION := RegEx.create_from_string(r"\s*(?<!\\)\[\s*(\S+?)\s*\]\s*")

static var locale_fallback : String

static func _static_init() -> void:
	locale_fallback = ProjectSettings.get_setting("internationalization/locale/fallback")

enum {
	STANDARD,
	APPENDAGE,
}

var declaration_type : int
var translations : Dictionary # [String, String]

var context : Cell

func _init(raw_string: String = ">") -> void:
	var cursor : int = 0
	var m_declaration_type := REGEX_DECLARATION_TYPE.search(raw_string, cursor)

	assert(m_declaration_type != null, "No declaration type in DialogMessage: `%s`." % raw_string)

	match m_declaration_type.get_string(1)[0]:
		">": declaration_type = STANDARD
		"+": declaration_type = APPENDAGE

	cursor = m_declaration_type.get_end()

	var tr_matches := REGEX_LANGUAGE_SEPARATION.search_all(raw_string, cursor)

	translations[""] = raw_string.substr(cursor) if tr_matches.is_empty() else raw_string.substr(cursor, tr_matches[0].get_start() - cursor)

	for i in tr_matches.size():
		cursor = tr_matches[i].get_end()
		var end := tr_matches[i+1].get_start() if i < tr_matches.size() - 1 else -1
		translations[tr_matches[i].get_string(1)] = raw_string.substr(cursor, end - cursor)

	for k in translations.keys():
		translations[k] = REGEX_MERGE_LINES.sub(translations[k], " ", true)

	print(self)


func _to_string() -> String:
	var declaration_str : String
	match declaration_type:
		STANDARD: declaration_str = ">"
		APPENDAGE: declaration_str = "+"
		_: declaration_str = "?"

	return "%s\t%s" % [
		declaration_str,
		str(translations)
	]


func get_raw_string(lang: String = OS.get_locale()) -> String:
	return translations.get(lang, translations.get(OS.get_locale_language(), translations.get(locale_fallback, translations[""])))


func get_display_string(lang: String = OS.get_locale()) -> DialogMessageSnapshot:
	return DialogMessageSnapshot.new_from_pure(get_raw_string(lang))


func interpolate(context := Cell.ROOT) -> String:
	return get_raw_string()
