@tool
extends Resource


#region Keyword

enum Keyword {
	ASK,
	AWAIT,
	CALL,
	DEF,
	ELIF,
	ELSE,
	EXIT,
	IF,
	JUMP,
	LABEL,
	LET,
	MATCH,
	PASS,
	PRINT,
	RETURN,
	SUSPEND,
	VAR,
	WHEN,
}

const KEYWORDS: PackedStringArray = [
	"ask",
	"await",
	"call",
	"def",
	"elif",
	"else",
	"exit",
	"if",
	"jump",
	"label",
	"let",
	"match",
	"pass",
	"print",
	"return",
	"suspend",
	"var",
	"when",
]

static func keyword_from_string(s: String) -> Keyword:
	return KEYWORDS.find(s)

#endregion


#region Assign

enum Assign {
	NONE = -1,
	SET,
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	FALLBACK,
	EXPRESS,
}

const ASSIGNS : PackedStringArray = [
	"=",
	"+=",
	"-=",
	"*=",
	"/=",
	"?=",
	"&=",
]

static func assignment_from_string(s: String) -> Assign:
	assert(s in ASSIGNS)
	return ASSIGNS.find(s)

static func assignment_to_string(v: Assign) -> String:
	return ASSIGNS[v] if v != Assign.NONE else "none"

#endregion


#region Operator

enum Operator {
	INVALID = -1,


	GROUP_CLOSE,
	GROUP_OPEN,
	ARRAY_CLOSE,
	ARRAY_OPEN,
	ITERATOR,
	ARROW_RIGHT,

	NEW,
	EVALUATE,
	ACCESS,

	IS_EQUAL,
	NOT_EQUAL,
	MORE_EQUAL,
	MORE_THAN,
	LESS_EQUAL,
	LESS_THAN,

	NOT,
	AND,
	OR,

	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	MODULO,
	BIT_AND,
	BIT_OR,

	QUESTION,
	DOT,
}

static var OPERATOR_PATTERNS: Dictionary[int, RegEx] = {
	Operator.GROUP_CLOSE:
		RegEx.create_from_string(r"\s*\)"),
	Operator.GROUP_OPEN:
		RegEx.create_from_string(r"\(\s*"),
	Operator.ARRAY_CLOSE:
		RegEx.create_from_string(r"\s*\]"),
	Operator.ARRAY_OPEN:
		RegEx.create_from_string(r"\[\s*"),
	Operator.ITERATOR:
		RegEx.create_from_string(r",\s*"),
	Operator.ARROW_RIGHT:
		RegEx.create_from_string(r"\->\s*"),

	Operator.IS_EQUAL:
		RegEx.create_from_string(r"=="),
	Operator.NOT_EQUAL:
		RegEx.create_from_string(r"!="),
	Operator.MORE_EQUAL:
		RegEx.create_from_string(r">="),
	Operator.MORE_THAN:
		RegEx.create_from_string(r">"),
	Operator.LESS_EQUAL:
		RegEx.create_from_string(r"<="),
	Operator.LESS_THAN:
		RegEx.create_from_string(r"<"),

	Operator.EVALUATE:
		RegEx.create_from_string(r"@"),
	Operator.DOT:
		RegEx.create_from_string(r"\."),
	Operator.QUESTION:
		RegEx.create_from_string(r"\?"),
	Operator.ACCESS:
		RegEx.create_from_string(r":"),

	Operator.NEW:
		RegEx.create_from_string(r"\bnew\b"),
	Operator.NOT:
		RegEx.create_from_string(r"!|\bnot\b"),
	Operator.AND:
		RegEx.create_from_string(r"&&|\band\b"),
	Operator.OR:
		RegEx.create_from_string(r"\|\||\bor\b"),

	Operator.ADD:
		RegEx.create_from_string(r"\+"),
	Operator.SUBTRACT:
		RegEx.create_from_string(r"\-+"),
	Operator.MULTIPLY:
		RegEx.create_from_string(r"\*"),
	Operator.DIVIDE:
		RegEx.create_from_string(r"\/"),
	Operator.MODULO:
		RegEx.create_from_string(r"%"),
	Operator.BIT_AND:
		RegEx.create_from_string(r"&"),
	Operator.BIT_OR:
		RegEx.create_from_string(r"\|"),
}

static var OPERATOR_PATTERN_COMPILED: RegEx = (func() -> RegEx:
	var results : PackedStringArray = []
	results.resize(OPERATOR_PATTERNS.size())
	for i in results.size():
		results[i] = OPERATOR_PATTERNS[i].get_pattern()

	return RegEx.create_from_string("|".join(results))
).call()

static func operator_from_string(text: String) -> Operator:
	for k in OPERATOR_PATTERNS:
		var m := OPERATOR_PATTERNS[k].search(text)
		if m:
			return k
	return -1

static func operator_to_string(operator: Operator) -> String:
	match operator:
		Operator.GROUP_CLOSE:
			return ")"
		Operator.GROUP_OPEN:
			return "("
		Operator.ARRAY_CLOSE:
			return "]"
		Operator.ARRAY_OPEN:
			return "["
		Operator.ITERATOR:
			return ","
		Operator.ARROW_RIGHT:
			return "->"

		Operator.IS_EQUAL:
			return '=='
		Operator.NOT_EQUAL:
			return '!='
		Operator.MORE_THAN:
			return '>'
		Operator.MORE_EQUAL:
			return '>='
		Operator.LESS_THAN:
			return '<'
		Operator.LESS_EQUAL:
			return '<='

		Operator.EVALUATE:
			return "@"
		Operator.DOT:
			return "."
		Operator.QUESTION:
			return "??"
		Operator.ACCESS:
			return ":"

		Operator.NEW:
			return 'new'
		Operator.NOT:
			return '!'
		Operator.AND:
			return '&&'
		Operator.OR:
			return '||'

		Operator.ADD:
			return "+"
		Operator.SUBTRACT:
			return "-"
		Operator.MULTIPLY:
			return "*"
		Operator.DIVIDE:
			return "/"
		Operator.MODULO:
			return "%"
		Operator.BIT_AND:
			return "&"
		Operator.BIT_OR:
			return "|"

	return "INVALID_OPERATOR"

#endregion


#region Literal
enum Literal {
	COLOR,
	NULL,
	BOOLEAN_TRUE,
	BOOLEAN_FALSE,
	NUMBER_DECIMAL,
	NUMBER_INTEGER,
}

static var LITERAL_PATTERNS: Dictionary[Literal, RegEx] = {
	Literal.COLOR:
		RegEx.create_from_string(r"(?i)#(?:[0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{3,4})(?![0-9a-f])"),

	Literal.NULL:
		RegEx.create_from_string(r"\b(?:[Nn]ull|NULL)\b"),

	Literal.BOOLEAN_TRUE:
		RegEx.create_from_string(r"\b(?:[Tt]rue|TRUE)\b"),

	Literal.BOOLEAN_FALSE:
		RegEx.create_from_string(r"\b(?:[Ff]alse|FALSE)\b"),

	Literal.NUMBER_DECIMAL:
		RegEx.create_from_string(r"\b(?:\d+\.\d+|\d+\.|\.\d+)\b"),

	Literal.NUMBER_INTEGER:
		RegEx.create_from_string(r"\b\d+\b"),
}

static func literal_from_string(text: String) -> Variant:
	for i in LITERAL_PATTERNS.size():
		var m: RegExMatch = LITERAL_PATTERNS[i].search(text)
		if not m: continue

		match i:
			Literal.COLOR: return Color(text)
			Literal.NULL: return null
			Literal.BOOLEAN_TRUE: return true
			Literal.BOOLEAN_FALSE: return false
			Literal.NUMBER_DECIMAL: return float(text)
			Literal.NUMBER_INTEGER: return int(text)

	return StringName(text)

#endregion


#region Type

enum Type {
	INDENTATION,
	STRING_BLOCK,
	STRING_QUOTED,
	KEYWORD,
	LITERAL_BOOLEAN,
	LITERAL_NULL,
	LITERAL_COLOR,
	ASSIGNMENT,
	OPERATOR,
	COMMENT,
	IDENTIFIER,
	LITERAL_NUMBER,
	TERMINATOR,
	WHITESPACE,

	MAX
}


const STRING_BLOCK_PATTERN := "(?m)(>)\\s*((?:\\S[^\\n]*(?:\\n+[ \\t]{%s,})?)*)"

static func compile_string_block_pattern(depth: int) -> void:
	TYPE_PATTERNS[Type.STRING_BLOCK].compile(STRING_BLOCK_PATTERN % (depth + 1))


static var TYPE_PATTERNS: Dictionary[Type, RegEx] = {
	Type.INDENTATION:
		RegEx.create_from_string(r"(?m)^\t+"),

	Type.STRING_BLOCK:
		RegEx.create_from_string(STRING_BLOCK_PATTERN % 0),

	Type.STRING_QUOTED:
		RegEx.create_from_string(r"(?<!\\)(['\"`])(.*?)(?<!\\)\1"),

	Type.KEYWORD:
		RegEx.create_from_string("\\b(?:%s)\\b" % "|".join(KEYWORDS)),

	Type.LITERAL_BOOLEAN:
		RegEx.create_from_string(r"\b(?:[Tt]rue|TRUE|[Ff]alse|FALSE)\b"),

	Type.LITERAL_COLOR:
		LITERAL_PATTERNS[Literal.COLOR],

	Type.ASSIGNMENT:
		RegEx.create_from_string(r"([+\-*\/?&]?)=(?!=)"),

	Type.OPERATOR:
		OPERATOR_PATTERN_COMPILED,

	Type.COMMENT:
		RegEx.create_from_string(r"(?ms)(([#/])\*.*?(\*\2))|((#|\/{2}).*?$)"),

	Type.IDENTIFIER:
		RegEx.create_from_string(r"~|(?:[a-zA-Z_]\w*)"),

	Type.LITERAL_NUMBER:
		RegEx.create_from_string(r"\d+\.\d*|\.?\d+"),

	Type.TERMINATOR:
		RegEx.create_from_string(r"(?m)(?<!\[)[:;\n]+(?!\])"),

	Type.WHITESPACE:
		RegEx.create_from_string(r"(?m)[ \n]+|(?<!^|\t)\t+"),

}

static var TYPE_STRINGS: Dictionary[Type, String] = {
	Type.INDENTATION:		"[ indent ]",
	Type.STRING_BLOCK:		"[  > str ]",
	Type.STRING_QUOTED:		"[  \"str\" ]",
	Type.KEYWORD:			"[ keywrd ]",
	Type.LITERAL_BOOLEAN: 	"[   bool ]",
	Type.LITERAL_COLOR: 	"[  color ]",
	Type.ASSIGNMENT: 		"[ assign ]",
	Type.OPERATOR: 			"[     op ]",
	Type.COMMENT: 			"[ coment ]",
	Type.IDENTIFIER:		"[     id ]",
	Type.LITERAL_NUMBER:	"[ number ]",
	Type.TERMINATOR: 		"[ termin ]",
	Type.WHITESPACE:		"[ wspace ]",
}

#endregion

@export_storage
var type: Type

@export_storage
var value: Variant


func _init(__type__: Type = -1, __value_match__: RegExMatch = null) -> void:
	type = __type__

	if __value_match__ == null:
		return

	match type:
		Type.INDENTATION:
			value = __value_match__.get_string().length()

		Type.KEYWORD:
			value = keyword_from_string(__value_match__.get_string())

		Type.ASSIGNMENT:
			value = assignment_from_string(__value_match__.get_string())

		Type.OPERATOR:
			value = operator_from_string(__value_match__.get_string())

		Type.STRING_BLOCK: value = Penny.Message.new_from_match_block(__value_match__)

		Type.STRING_QUOTED: value = Penny.Message.new_or_pure_from_match_quoted(__value_match__)

		Type.LITERAL_BOOLEAN, \
		Type.LITERAL_COLOR, \
		Type.LITERAL_NUMBER:
			value = literal_from_string(__value_match__.get_string())

		_:
			value = StringName(__value_match__.get_string())


func _to_string() -> String:
	var value_string: String

	match type:
		Type.INDENTATION:
			value_string = "|---".repeat(value)

		Type.KEYWORD:
			value_string = KEYWORDS[value]

		Type.ASSIGNMENT:
			value_string = ASSIGNS[value] if value >= 0 else "invalid"

		Type.OPERATOR:
			value_string = operator_to_string(value)

		Type.STRING_QUOTED when value is String:
			value_string = "\"%s\"" % str(value)

		_:
			value_string = str(value)


	return "%s %s" % [
		TYPE_STRINGS[type],
		value_string,
	]
