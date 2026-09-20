# Contains a translation table and can be purified/evaluated at a specific moment in time.
@tool
extends Resource

static var REGEX_SEPARATE_TRANSLATIONS := RegEx.create_from_string("(?:\\s*)%s\\[([a-zA-Z\\-]+)\\](?:\\s*)" % PennyScript.MessageParser.ODD_ESCAPE_PATTERN)

static func new_from_match_block(m: RegExMatch) -> Penny.Message:
	return Penny.Message.new(m.get_string(2))


static func new_or_pure_from_match_quoted(m: RegExMatch) -> Variant:
	match m.get_string(1)[0]:
		"`":
			return Penny.Message.new(m.get_string(2))
		_:
			return m.get_string(2)


## Dictionary of language code keys to text values. Values can be an assortment of [String] or [Penny.Text].
@export_storage
var translations: Dictionary[StringName, Variant]

var translation_default: String:
	get:
		if translations.is_empty():
			return ""

		elif translations.has(&""):
			return str(translations[&""])

		else:
			return str(translations[translations.keys()[0]])


func _init(__raw__: String = "") -> void:
	translations = {}

	var cursor := 0
	var lang := &""
	while cursor < __raw__.length():
		var m := REGEX_SEPARATE_TRANSLATIONS.search(__raw__, cursor)
		if m == null:
			set_translation(lang, __raw__.substr(cursor))
			break

		set_translation(lang, __raw__.substr(cursor, m.get_start() - cursor))

		lang = m.get_string(1)
		cursor = m.get_end()


func _to_string() -> String:
	var result : String = ""

	if translations.is_empty():
		result = "[empty]"

	elif translations.has(&""):
		result = "« %s »" % translations[&""]

	else:
		var k : StringName = translations.keys()[0]
		result = "[%s] « %s »" % [
			k,
			translations[k]
		]

	if translations.size() > 1:
		result += " [+%s]" % str(translations.size() - 1)

	return result


func print_translations() -> void:
	if translations.is_empty():
		print("\n[empty]\n")
		return

	var result : String = "\n"
	for t in translations:
		result += "[%s] « %s »\n\n" % [
			t,
			translations[t]
		]
	print(result.left(-1))



func get_translation(lang: StringName) -> Variant:
	return translations.get(lang, translations.get(&"", ""))


func set_translation(lang: StringName, text: String) -> void:
	if text.is_empty():
		translations.erase(lang)
	else:
		translations[lang] = text


## Adds missing translations from another message into this one, and populates them with this message's default translation.
func append_missing_translations(other: Penny.Message) -> void:
	for t in other.translations:
		if translations.has(t):
			continue

		translations[t] = translation_default




## Returns a copy of this [Penny.Message] where all translations have been parsed.
func purified(object_context) -> Penny.Message:
	var parser := PennyScript.MessageParser.new(object_context, object_context)
	var result : Penny.Message = duplicate_deep()
	parser.process(result)

	return result
