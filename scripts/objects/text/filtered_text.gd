
## Text that can has been interpolated and filtered but is not yet displayable.
class_name FilteredText extends Text


static func from_raw(raw: String, context: PennyObject) -> FilteredText:

	# print("FilteredText -> Raw: '%s', context: %s" % [raw, context.self_key])

	## INTERPOLATION
	while true:
		var pattern_match := INTERPOLATION_PATTERN.search(raw)
		if not pattern_match: break

		var interp_expr_string := pattern_match.get_string(1) + pattern_match.get_string(2)	## ~= $1$2
		var inter_expr := Expr.from_tokens(PennyScript.parse_tokens_from_raw(interp_expr_string))
		var result = inter_expr.evaluate(context)
		var result_string : String
		if result == null:
			result_string = "NULL"
		elif result is PennyObject:
			result_string = result.rich_name.text
		elif result is Color:
			result_string = "#" + result.to_html()
		else:
			result_string = str(result)

		raw = sub_match(pattern_match, result_string)

	## FILTERS
	var filters : Array = context.get_value_or_default(PennyObject.FILTERS_KEY, [])
	for filter_path in filters:

		var filter : PennyObject = filter_path.evaluate(context)
		var pattern := RegEx.create_from_string(filter.get_value(PennyObject.FILTER_PATTERN_KEY))
		var replace : String = filter.get_value(PennyObject.FILTER_REPLACE_KEY)

		var start := 0
		while true:
			var pattern_match := pattern.search(raw, start)
			if not pattern_match: break

			var tag_match_found := false
			var tag_matches := DECO_TAG_PATTERN.search_all(raw, start)
			for tag_match in tag_matches:
				if pattern_match.get_start() > tag_match.get_start() and pattern_match.get_start() <= tag_match.get_end():
					start = tag_match.get_end()
					tag_match_found = true
					break
			if tag_match_found:
				continue

			raw = pattern.sub(raw, replace, false, start)
			start = pattern_match.get_start() + replace.length()

	# print("FilteredText -> Filtered: '%s'" % raw)

	return FilteredText.new(raw)


func to_decorated() -> DecoratedText:
	return DecoratedText.from_filtered(self)


static func from_many(many: Array[FilteredText]) -> FilteredText:
	var result := FilteredText.new()
	for i in many:
		result.text += i.text
	return result


func append(other: FilteredText) -> void:
	self.text += other.text


func append_raw(raw: String, context: PennyObject) -> void:
	self.append(FilteredText.from_raw(raw, context))
