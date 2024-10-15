
## Single token in script.
@tool
class_name Token extends Object

# enum Type {
# 	LITERAL,
# 	OPERATOR,
# 	KEYWORD,
# 	IDENTIFIER
# }

enum {
	INDENTATION,		## NOT ADDED TO STATEMENTS
	VALUE_STRING,		## Multiline
	# ARRAY_CAPS,
	# PARENTHESIS_CAPS,
	VALUE_COLOR,
	VALUE_NUMBER,
	VALUE_BOOLEAN,
	OPERATOR,
	# OPERATOR_GENERIC,
	# OPERATOR_BOOLEAN,
	# OPERATOR_NUMERIC,
	# OPERATOR_NUMERIC_EQUALITY,
	COMMENT,
	ASSIGNMENT,
	KEYWORD,
	IDENTIFIER,
	TERMINATOR,			## NOT ADDED TO STATEMENTS
	WHITESPACE,			## NOT ADDED TO STATEMENTS
}

static func enum_to_string(idx: int) -> String:
	match idx:
		INDENTATION: return "indent"
		VALUE_STRING: return "string"
		VALUE_COLOR: return "color"
		VALUE_NUMBER: return "number"
		VALUE_BOOLEAN: return "boolean"
		OPERATOR: return "operator"
		COMMENT: return "comment"
		ASSIGNMENT: return "assigner"
		KEYWORD: return "keyword"
		IDENTIFIER: return "identifier"
		TERMINATOR: return "terminator"
		WHITESPACE: return "whitespace"
		_: return "invalid_token"


static var PATTERNS : Array[RegEx] = [
	RegEx.create_from_string("(?m)^\\t+"),
	RegEx.create_from_string("(?s)(\"\"\"|\"|'''|'|```|`).*?\\1"),
	# RegEx.create_from_string("(?s)[\\[\\]]|,(?=.*\\])"),
	# RegEx.create_from_string("(?s)[\\(\\)]"),
	RegEx.create_from_string("(?i)#([0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{3,4})(?![0-9a-f])"),
	RegEx.create_from_string("\\d+\\.\\d*|\\.?\\d+"),
	RegEx.create_from_string("\\b([Tt]rue|TRUE|[Ff]alse|FALSE)\\b"),
	RegEx.create_from_string("([=!<>]=)|&&|\\|\\||(\\b(and|nand|or|nor|not)\\b)|([!+\\-*/%&|<>()](?!=))|(\\b\\.\\b)"),
	# RegEx.create_from_string("(\\b\\.\\b)|==|!="),
	# RegEx.create_from_string("!|&&|\\|\\||(\\b(and|nand|or|nor|not)\\b)"),
	# RegEx.create_from_string("\\+|-|\\*|/|%|&|\\|"),
	# RegEx.create_from_string(">|<|<=|>="),
	RegEx.create_from_string("(?ms)(([#/])\\*.*?(\\*\\2))|((#|\\/{2}).*?$)"),
	RegEx.create_from_string("[+\\-*/:]?="),
	RegEx.create_from_string("\\b(dec|dive|elif|else|if|filter|jump|label|menu|object|pass|print|return|rise|suspend)\\b"),
	RegEx.create_from_string("[a-zA-Z_]\\w*"),
	RegEx.create_from_string("(?m)[:;]|((?<=[^\\n:;])$\\n)"),
	RegEx.create_from_string("(?m)[ \\n]+|(?<!^|\\t)\\t+"),
]


enum Literal {
	STRING,
	NULL,
	BOOLEAN_TRUE,
	BOOLEAN_FALSE,
	NUMBER_DECIMAL,
	NUMBER_INTEGER,
	COLOR,
}

static var PRIMITIVE_PATTERNS = [
	RegEx.create_from_string("(?s)(?<=(\"\"\"|\"|'''|'|```|`)).*?(?=\\1)"),
	RegEx.create_from_string("\\b([Nn]ull|NULL)\\b"),
	RegEx.create_from_string("\\b([Tt]rue|TRUE)\\b"),
	RegEx.create_from_string("\\b([Ff]alse|FALSE)\\b"),
	RegEx.create_from_string("\\d+\\.\\d+|\\d+\\.|\\.\\d+"),
	RegEx.create_from_string("\\d+"),
	PATTERNS[Token.VALUE_COLOR],
]

enum Operator {
	INVALID,
	NOT,		# !  , not
	AND,		# && , and
	OR,			# || , or
	IS_EQUAL,		# ==
	NOT_EQUAL, # !=
}

var type : int
var value : Variant

func _init(_type: int, _raw: String) -> void:
	type = _type
	value = interpret(_raw)

func _to_string() -> String:
	match type:
		VALUE_STRING:
			return "`%s` (%s)" % [str(value), enum_to_string(type)]
		_:
			return "%s (%s)" % [str(value), enum_to_string(type)]

func get_operator_type() -> Operator:
	match value:
		'!', 'not': return Operator.NOT
		'&&', 'and': return Operator.AND
		'||', 'or': return Operator.OR
		'==': return Operator.IS_EQUAL
		'!=': return Operator.NOT_EQUAL
	push_error("%s is not a valid operator")
	return Operator.INVALID

func get_operator_token_count() -> int:
	if get_operator_type() == 1:
		return 1
	if get_operator_type() > 1:
		return 2
	return -1

static func interpret(s: String) -> Variant:
	var result : Variant = s

	for i in PRIMITIVE_PATTERNS.size():
		var match : RegExMatch = PRIMITIVE_PATTERNS[i].search(s)
		if not match:
			continue

		match i:
			Literal.NULL:
				return null
			Literal.BOOLEAN_TRUE:
				return true
			Literal.BOOLEAN_FALSE:
				return false
			Literal.NUMBER_DECIMAL:
				return float(s)
			Literal.NUMBER_INTEGER:
				return int(s)
			Literal.COLOR:
				return Color(s)
			Literal.STRING:
				return match.get_string()

	return StringName(s)
