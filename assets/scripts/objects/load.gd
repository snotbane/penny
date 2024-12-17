
class_name Load extends Object


static func any(json: Variant) -> Variant:
	if json is String:
		match json[0]:
			"/": return Path.new_from_string(json)
			"$": return Lookup.new_from_string(json)
			"#": return Color.html(json)
	return json
