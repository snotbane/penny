
## Single token in script representing a clause or raw.
class_name Token extends Object

enum {
	INDENTATION,		## NOT ADDED TO STATEMENTS
	VALUE_STRING,		## Multiline
	ARRAY_CAPS,
	PARENTHESIS_CAPS,
	VALUE_COLOR,
	VALUE_NUMBER,
	VALUE_BOOLEAN,
	OPERATOR_GENERIC,
	OPERATOR_BOOLEAN,
	OPERATOR_NUMERIC,
	OPERATOR_NUMERIC_EQUALITY,
	COMMENT,
	ASSIGNMENT,
	KEYWORD,
	IDENTIFIER,
	TERMINATOR,			## NOT ADDED TO STATEMENTS
	WHITESPACE,			## NOT ADDED TO STATEMENTS
}

static var PATTERNS = [
	RegEx.create_from_string("(?m)^\\t+"),
	RegEx.create_from_string("(?s)(\"\"\"|\"|'''|'|```|`).*?\\1"),
	RegEx.create_from_string("(?s)[\\[\\]]|,(?=.*\\])"),
	RegEx.create_from_string("(?s)[\\(\\)]"),
	RegEx.create_from_string("(?i)#([0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{3,4})(?![0-9a-f])"),
	RegEx.create_from_string("(?<=[^\\d\\.])(\\d+\\.\\d+|\\.\\d+|\\d+\\.|\\d+)(?=[^\\d\\.])"),
	RegEx.create_from_string("\\b(true|True|TRUE|false|False|FALSE)\\b"),
	RegEx.create_from_string("(\\b\\.\\b)|==|!="),
	RegEx.create_from_string("!|&&|\\|\\||(\\b(and|nand|or|nor|not)\\b)"),
	RegEx.create_from_string("\\+|-|\\*|/|%|&|\\|"),
	RegEx.create_from_string(">|<|<=|>="),
	RegEx.create_from_string("(([#/])\\*(.|\\n)*?(\\*\\2|$))|((#|\\/\\/).*(?=\\n))"),
	RegEx.create_from_string("\\+=|-=|\\*=|/=|=|is"),
	RegEx.create_from_string("\\b(dec|dive|elif|else|if|filter|jump|label|menu|object|pass|print|return|rise|suspend)\\b"),
	RegEx.create_from_string("[a-zA-Z_]\\w*"),
	RegEx.create_from_string("(?m)[:;]|((?<=[^\\n:;])$\\n)"),
	RegEx.create_from_string("(?m)[ \\n]+|(?<!^|\\t)\\t+"),
]

static var RX_BOOLEAN_OPERATOR = RegEx.create_from_string("((\\b\\.\\b)|==|!=|!|&&|\\|\\|)|(\\b(and|nand|or|nor|not)\\b)")
static var RX_STRING_TRIM = RegEx.create_from_string("(?s)(?<=(\"\"\"|\"|'''|'|```|`)).*?(?=\\1)")

var type : int
var line : int
var col : int
var raw : String

var col_end : int :
	get: return col + raw.length()

var belongs_in_expression_variant : bool :
	get: return type >= VALUE_STRING && type <= OPERATOR_NUMERIC_EQUALITY

var belongs_in_expression_boolean : bool :
	get: return type == PARENTHESIS_CAPS || ( type >= VALUE_BOOLEAN && type <= OPERATOR_BOOLEAN )

func _init(_type: int, _line: int, _col: int, _raw: String) -> void:
	type = _type
	line = _line
	col = _col
	raw = _raw

func equals(other: Token) -> bool:
	return raw == other.raw

func _to_string() -> String:
	return "ln %s cl %s type %s : %s" % [line, col, type, raw]
