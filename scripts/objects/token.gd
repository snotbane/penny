
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
	KEYWORD,
	VALUE_BOOLEAN,
	VALUE_COLOR,
	OPERATOR,
	COMMENT,
	ASSIGNMENT,
	IDENTIFIER,
	VALUE_NUMBER,
	TERMINATOR,			## NOT ADDED TO STATEMENTS
	WHITESPACE,			## NOT ADDED TO STATEMENTS
}

static var PATTERNS := {
	Token.INDENTATION: 		RegEx.create_from_string("(?m)^\\t+"),
	Token.VALUE_STRING: 	RegEx.create_from_string("(?s)(\"\"\"|\"|'''|'|```|`).*?\\1"),
	Token.KEYWORD: 			RegEx.create_from_string("\\b(dec|dive|call|elif|else|if|filter|jump|label|open|pass|print|return|rise|suspend)\\b"),
	Token.VALUE_BOOLEAN: 	RegEx.create_from_string("\\b([Tt]rue|TRUE|[Ff]alse|FALSE)\\b"),
	Token.VALUE_COLOR: 		RegEx.create_from_string("(?i)#(?:[0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{3,4})(?![0-9a-f])"),
	Token.OPERATOR: 		RegEx.create_from_string("([=!<>]=)|&&|\\|\\||(\\b(and|nand|or|nor|not|new)\\b)|([\\.!+\\-*/@\\$%&|<>\\[\\]\\(\\),](?!=))"),
	Token.COMMENT: 			RegEx.create_from_string("(?ms)(([#/])\\*.*?(\\*\\2))|((#|\\/{2}).*?$)"),
	Token.ASSIGNMENT: 		RegEx.create_from_string("[+\\-*/:]?="),
	Token.IDENTIFIER: 		RegEx.create_from_string("[a-zA-Z_]\\w*"),
	Token.VALUE_NUMBER: 	RegEx.create_from_string("\\d+\\.\\d*|\\.?\\d+"),
	Token.TERMINATOR: 		RegEx.create_from_string("(?m)[:;]|((?<=[^\\n:;])$\\n)"),
	Token.WHITESPACE: 		RegEx.create_from_string("(?m)[ \\n]+|(?<!^|\\t)\\t+"),
}

static func enum_to_string(idx: int) -> String:
	match idx:
		INDENTATION: return "indent"
		VALUE_STRING: return "string"
		KEYWORD: return "keyword"
		VALUE_BOOLEAN: return "boolean"
		VALUE_COLOR: return "color"
		VALUE_NUMBER: return "number"
		OPERATOR: return "operator"
		COMMENT: return "comment"
		ASSIGNMENT: return "assigner"
		IDENTIFIER: return "identifier"
		TERMINATOR: return "terminator"
		WHITESPACE: return "whitespace"
		_: return "invalid_token"


enum Literal {
	STRING,
	COLOR,
	NULL,
	BOOLEAN_TRUE,
	BOOLEAN_FALSE,
	NUMBER_DECIMAL,
	NUMBER_INTEGER,
}

static var PRIMITIVE_PATTERNS = [
	RegEx.create_from_string("(?s)(?<=(\"\"\"|\"|'''|'|```|`)).*?(?=\\1)"),
	PATTERNS[Token.VALUE_COLOR],
	RegEx.create_from_string("\\b([Nn]ull|NULL)\\b"),
	RegEx.create_from_string("\\b([Tt]rue|TRUE)\\b"),
	RegEx.create_from_string("\\b([Ff]alse|FALSE)\\b"),
	RegEx.create_from_string("(?<!\\D)(\\d+\\.\\d+|\\d+\\.|\\.\\d+)(?!=\\D)"),
	RegEx.create_from_string("(?<!\\D)\\d+(?!=\\D)"),
]

enum Operator {
	INVALID,
	DEREF,		# @
	LOOKUP,		# $
	NOT,		# !  , not
	AND,		# && , and
	OR,			# || , or
	IS_EQUAL,	# ==
	NOT_EQUAL,	# !=
	DOT,		# .
	QUESTION,	# ?

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
	if type == OPERATOR:
		match value:
			'!', 'not': return Operator.NOT
			'$': return Operator.LOOKUP
			'&&', 'and': return Operator.AND
			'||', 'or': return Operator.OR
			'==': return Operator.IS_EQUAL
			'!=': return Operator.NOT_EQUAL
			'.': return Operator.DOT
			'@': return Operator.DEREF
			'?': return Operator.QUESTION
	return Operator.INVALID

func get_operator_token_count() -> int:
	if type != OPERATOR: return -1
	match get_operator_type():
		Operator.DOT:
			return 0
		Operator.NOT, Operator.LOOKUP, Operator.DEREF:
			return 1
		_:
			return 2

static func interpret(s: String) -> Variant:
	for i in PRIMITIVE_PATTERNS.size():
		var match : RegExMatch = PRIMITIVE_PATTERNS[i].search(s)
		if not match:
			continue

		match i:
			Literal.STRING:
				return match.get_string()
			Literal.COLOR:
				return Color(s)
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

	return StringName(s)
