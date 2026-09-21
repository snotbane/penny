@tool
extends RefCounted

const ODD_ESCAPE_PATTERN := "(?:(?<!\\\\)(?:\\\\{2})*)"

static var VISCHAR_PATTERN := RegEx.create_from_string(r"\[(.*?)\]")
static var VISCHAR_SUBSTITUTIONS : Dictionary[String, String] = {
	"lb": "[",
	"rb": "]",
}

## Given a list of [RegEx], searches the given [String] and returns a successful match, depending on *which match appears earliest in the [String]*.
static func regex_get_first_match_in_string_tuple(string: String, rlist: Array[RegEx], start: int = 0) -> Array:
	var regex_out: RegEx = null
	var match_out: RegExMatch = null

	for r in rlist:
		var m := r.search(string, start)
		if m == null:
			continue

		if match_out and match_out.get_start() < m.get_start():
			continue

		regex_out = r
		match_out = m

	return [ regex_out, match_out ]


## Given a list of [RegEx], searches the given [String] and returns the first successful match found *in the list*.
static func regex_get_first_match_in_list_tuple(string: String, rlist: Array[RegEx], start: int = 0) -> Array:
	for r in rlist:
		var m := r.search(string, start)
		if m == null:
			continue

		return [ r, m ]

	return [ null, null ]

static func regex_replace_match(m: RegExMatch, s: String) -> String:
	return m.subject.left(m.get_start()) + s + m.subject.right(-m.get_end())

var object_context: Variant
var filter_context: Variant

var source: Variant
var translation: StringName

func _init(__object_context__, __filter_context__) -> void:
	object_context = __object_context__
	filter_context = __filter_context__


func process(__source__) -> Variant:
	source = __source__
	if source is String:
		return purify(source, &"")

	elif source is Penny.Message:
		for t in source.translations:
			source.translations[t] = purify(source.translations[t], t)
		# source.print_translations()
		return source

	return ""


func purify(string: String, t: StringName) -> Variant:
	translation = t

	if object_context:
		string = interpolate(string, object_context)
		string = filtrate(string, filter_context)

	return decorate(string, object_context)


static var REGEX_INTERPOLATE_PATH := RegEx.create_from_string("%s(?:@((?:\\.?[A-Za-z_]\\w*)+))" % [ ODD_ESCAPE_PATTERN ])
static var REGEX_INTERPOLATE_EXPRESS := RegEx.create_from_string("%s\\{(.*?)%s\\}" % [ ODD_ESCAPE_PATTERN, ODD_ESCAPE_PATTERN ])

static var RLIST_INTERPOLATE : Array[RegEx] = [
	REGEX_INTERPOLATE_PATH,
	REGEX_INTERPOLATE_EXPRESS,
]

func interpolate(string: String, initial_context) -> String:
	while true:
		var tuple := regex_get_first_match_in_string_tuple(string, RLIST_INTERPOLATE)

		var r: RegEx = tuple[0]
		var m: RegExMatch = tuple[1]
		var match_string : String
		var interp_tuple

		match r:
			REGEX_INTERPOLATE_PATH:
				match_string = m.get_string(1)
				interp_tuple = (
					Penny.Path.new_from_string(match_string)
						.evaluate_adaptive(initial_context)
				)

			REGEX_INTERPOLATE_EXPRESS:
				match_string = m.get_string(1)
				interp_tuple = (
					Penny.Express.new_or_literal_from_string(match_string, true)
						.evaluate_adaptive(initial_context)
				)

			_:
				break

		var interp_context : Variant = interp_tuple[0]
		var interp_value : Variant = interp_tuple[1]
		var interp_string : String

		if interp_value == null:
			interp_string = (
				("\\@%s" % match_string)
				if match_string
				else ("\\[ %s \\]" % match_string)
			)
		elif interp_value is Penny.Cell:
			interp_context = interp_value
			interp_value = interp_value.display_text
		elif interp_value is Color:
			interp_string = "#%s" % interp_value.to_html()
		else:
			interp_string = str(interp_value)

		if interp_value is Penny.Message:
			if source is Penny.Message:
				source.append_missing_translations(interp_value)
			interp_string = interp_value.get_translation(translation)

		string = regex_replace_match(
			m,
			interpolate(interp_string, interp_context)
		)

	return string

# var interpolation_path_tuple_cache: Dictionary[Penny.Path, Array]

# func retrieve_cached_path_adaptive_tuple(path: Penny.Path, context) -> Array:
# 	for k in interpolation_path_tuple_cache:
# 		if path.is_match(k):
# 			return interpolation_path_tuple_cache[k]

# 	var result = path.evaluate_adaptive(context)
# 	interpolation_path_tuple_cache[path] = result
# 	return result



func filtrate(string: String, filter_context) -> String:
	if filter_context is not Penny.Cell:
		printerr("Can't filtrate from a filter_context which isn't a Cell. (%s)" % filter_context)
		return string

	var filters = filter_context.get_data(&"filters")
	if filters == null:
		return string

	assert(filters is Array, "The object value 'filters' must be an Array consisting only of [Penny.Text.Filter]s.")

	for filter: Penny.Text.Filter in filters:
		assert(filter is Penny.Text.Filter, "Only [Penny.Text.Filter]s are supported for filtration. Use the syntax `\"pattern\" -> replace` to create one. `pattern` must be a String, and `replace` can be anything.")

		string = filter.process(string, translation)

	return string


static var REGEX_DECORATE_ESCAPE := RegEx.create_from_string(r"\\(.)")
static var ESCAPE_SUBSITUTIONS : Dictionary[String, String] = {
	"\\": "\\",
	"n": "\n",
	"t": "\t",
	"[": "<lb>",
	"]": "<rb>",
}

static var REGEX_DECORATE_TAG := RegEx.create_from_string("%s<(?:\\s*(\\/))?\\s*((?:\\S.*?)?)\\s*%s>" % [
	ODD_ESCAPE_PATTERN, ODD_ESCAPE_PATTERN
])

static var RLIST_DECORATE : Array[RegEx] = [
	REGEX_DECORATE_ESCAPE,
	REGEX_DECORATE_TAG
]

static var REGEX_DECORATION_SPLIT := RegEx.create_from_string(
	"%s(\\|)" % [ ODD_ESCAPE_PATTERN ]
)
static var REGEX_TAG_ARG := RegEx.create_from_string(
	r"([^=\s]+)\s*=\s*(?:(?:\{(.*?)\})|([^\s]+))"
)

static var REGEX_DECORATION_ARGUMENT_EXPRESS := RegEx.create_from_string(
	r"(?is)([a-z_][a-z_0-9]*)\s*=\s*\[\s*(.*?)\s*\]\s*"
)
static var REGEX_DECORATION_ARGUMENT_STRING := RegEx.create_from_string(
	r"(?is)([a-z_][a-z_0-9]*)\s*=\s*(['\"`]{3}|['\"`])(.+?)\2\s*"
)
static var REGEX_DECORATION_ARGUMENT_SINGLE := RegEx.create_from_string(
	r"(?i)([a-z_][a-z_0-9]*)\s*=\s*(\S+)\s*"
)
static var REGEX_DECORATION_ARGUMENT_STANDALONE := RegEx.create_from_string(
	r"(?i)([a-z_][a-z_0-9]*)\s*"
)

static var RLIST_DECORATION_ARGUMENT : Array[RegEx] = [
	REGEX_DECORATION_ARGUMENT_EXPRESS,
	REGEX_DECORATION_ARGUMENT_STRING,
	REGEX_DECORATION_ARGUMENT_SINGLE,
	REGEX_DECORATION_ARGUMENT_STANDALONE,
]


func decorate(string: String, object_context) -> Penny.Text:
	var result := Penny.Text.new(string)

	while true:
		var tuple := regex_get_first_match_in_string_tuple(result.text, RLIST_DECORATE)
		var r_tag: RegEx = tuple[0]
		var m_tag: RegExMatch = tuple[1]
		var match_string: String


		match r_tag:
			REGEX_DECORATE_ESCAPE:
				match_string = m_tag.get_string(1)
				result.text = regex_replace_match(
					m_tag,
					ESCAPE_SUBSITUTIONS.get(match_string, match_string)
				)

			REGEX_DECORATE_TAG:
				match_string = m_tag.get_string(2)
				var tag := Penny.Text.Tag.new(int(not m_tag.get_string(1).is_empty()))

				var decoration_strings: PackedStringArray
				var start_decoration := 0
				while true:
					var m_split := REGEX_DECORATION_SPLIT.search(match_string, start_decoration)
					if not m_split:
						break

					decoration_strings.push_back(match_string.substr(start_decoration, m_split.get_start() - start_decoration))
					start_decoration = m_split.get_end()
				decoration_strings.push_back(match_string.right(start_decoration))

				for decoration_string in decoration_strings:
					var decoration := Penny.Text.DecInst.new()

					var start_arg := 0
					while true:
						var arg_tuple := regex_get_first_match_in_list_tuple(
							decoration_string,
							RLIST_DECORATION_ARGUMENT,
							start_arg
						)
						var r_arg: RegEx = arg_tuple[0]
						var m_arg: RegExMatch = arg_tuple[1]

						match r_arg:
							REGEX_DECORATION_ARGUMENT_EXPRESS:
								decoration.add_argument(
									m_arg.get_string(1),
									Penny.Express.new_or_literal_from_string(m_arg.get_string(2))
								)

							REGEX_DECORATION_ARGUMENT_STRING:
								decoration.add_argument(
									m_arg.get_string(1),
									m_arg.get_string(3)
								)

							REGEX_DECORATION_ARGUMENT_SINGLE:
								decoration.add_argument(
									m_arg.get_string(1),
									Penny.Express.new_or_literal_from_string(m_arg.get_string(2))
								)

							REGEX_DECORATION_ARGUMENT_STANDALONE:
								decoration.add_argument(
									m_arg.get_string(1),
									null
								)

							_:
								printerr("Couldn't determine argument from text: %s" % decoration_string)
								break

						start_arg = m_arg.get_end()

					tag.add_decoration(decoration)

				result.text = regex_replace_match(m_tag, "")

			_:
				break

	for tag in result.tags:
		pass

	return result
