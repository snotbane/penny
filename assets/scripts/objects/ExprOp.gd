class_name Op extends RefCounted

## This order determines the priority in which they are applied, if two or more are encountered in a row (lowest value first).
enum {
	INVALID,

	NEW,
	EVALUATE,

	GROUP_CLOSE,
	GROUP_OPEN,
	ARRAY_CLOSE,
	ARRAY_OPEN,
	ITERATOR,

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

static var PATTERNS : Dictionary[int, RegEx] = {
	GROUP_CLOSE: 				RegEx.create_from_string(r"\)"),
	GROUP_OPEN: 				RegEx.create_from_string(r"\("),
	ARRAY_CLOSE: 				RegEx.create_from_string(r"\]"),
	ARRAY_OPEN: 				RegEx.create_from_string(r"\["),
	ITERATOR: 					RegEx.create_from_string(r","),

	IS_EQUAL: 					RegEx.create_from_string(r"=="),
	NOT_EQUAL: 					RegEx.create_from_string(r"!="),
	MORE_EQUAL: 				RegEx.create_from_string(r">="),
	MORE_THAN: 					RegEx.create_from_string(r">"),
	LESS_EQUAL: 				RegEx.create_from_string(r"<="),
	LESS_THAN: 					RegEx.create_from_string(r"<"),

	EVALUATE:					RegEx.create_from_string(r"@"),
	DOT: 						RegEx.create_from_string(r"\."),
	QUESTION: 					RegEx.create_from_string(r"\?"),

	NEW: 						RegEx.create_from_string(r"\bnew\b"),
	NOT:						RegEx.create_from_string(r"!|\bnot\b"),
	AND:						RegEx.create_from_string(r"&&|\band\b"),
	OR:							RegEx.create_from_string(r"\|\||\bor\b"),

	ADD:						RegEx.create_from_string(r"\+"),
	SUBTRACT:					RegEx.create_from_string(r"\-"),
	MULTIPLY:					RegEx.create_from_string(r"\*"),
	DIVIDE:						RegEx.create_from_string(r"\/"),
	MODULO:						RegEx.create_from_string(r"%"),
	BIT_AND:					RegEx.create_from_string(r"&"),
	BIT_OR:						RegEx.create_from_string(r"\|"),
}

static var PATTERN_COMPILED : RegEx

static func _static_init() -> void:
	var compiled_string := r""
	for k in PATTERNS.keys():
		compiled_string += PATTERNS[k].get_pattern() + "|"
	PATTERN_COMPILED = RegEx.create_from_string(compiled_string.substr(0, compiled_string.length() - 1))


static func new_from_string(s: String) -> Op:
	for k in PATTERNS.keys():
		var match : RegExMatch = PATTERNS[k].search(s)
		if match: return Op.new(k)
	return Op.new()


var type : int


var symbols_required : int :
	get:
		match type:
			ARRAY_OPEN, ARRAY_CLOSE, ITERATOR, NEW:		return 0
			EVALUATE, NOT:								return 1
			_:											return 2


func _init(_type: int = INVALID) -> void:
	type = _type


func _to_string() -> String:
	match type:
		GROUP_CLOSE:	return ")"
		GROUP_OPEN:		return "("
		ARRAY_CLOSE:	return "]"
		ARRAY_OPEN:		return "["
		ITERATOR:		return ","

		IS_EQUAL:		return '=='
		NOT_EQUAL:		return '!='
		MORE_THAN:		return '>'
		MORE_EQUAL:		return '>='
		LESS_THAN:		return '<'
		LESS_EQUAL:		return '<='

		EVALUATE:		return "@"
		DOT:			return "."
		QUESTION:		return "??"

		NEW:			return 'new'
		NOT:			return '!'
		AND:			return '&&'
		OR:				return '||'

		ADD:			return "+"
		SUBTRACT:		return "-"
		MULTIPLY:		return "*"
		DIVIDE:			return "/"
		MODULO:			return "%"
		BIT_AND:		return "&"
		BIT_OR:			return "|"
	return "INVALID_OP"


func export_json() -> Variant:
	return type

func import_json(json: Variant) -> void:
	type = json


func apply_init(stack: Array[Variant]) -> void:
	match type:
		ARRAY_OPEN:
			stack.push_back([])
			return
		ARRAY_CLOSE:
			var arr : Array = stack.pop_back()
			while stack:
				var pop = stack.pop_back()
				if pop is StringName:
					pop = Path.new([pop], false)
				arr.push_front(pop)
			stack.push_back(arr)
			return
		DOT:
			match stack.size():
				0:
					stack.push_back(Path.NEW)
				1:
					stack.push_back(Path.new([stack.pop_back()], true))
				_:
					var b = stack.pop_back()
					var a = stack.pop_back()
					if a is Path:
						a.ids.push_back(b)
						stack.push_back(a)
					elif a is StringName:
						stack.push_back(Path.new([a, b], false))
					else:
						stack.push_back(a)
						stack.push_back(Path.new([b], true))


func apply(stack: Array[Variant], context: Cell) -> void:
	match type:
		NEW:
			var data : Dictionary = {}
			data[Cell.K_PROTOTYPE] = stack.pop_back() if stack else Path.DEFAULT_BASE
			stack.push_back(Cell.new(Cell.NEW_OBJECT_KEY_NAME, context, data))
			return
		EVALUATE:
			stack.push_back(stack.pop_back().evaluate(context))
			return

	var abc : Array[Variant] = []
	for i in symbols_required:
		abc.push_front(stack.pop_back())

	for i in abc.size():
		if abc[i] is Evaluable:
			abc[i] = abc[i].evaluate(context)

	match type:
		QUESTION:		stack.push_back(abc[0] if abc[0] != null else abc[1])
		NOT:			stack.push_back(		! abc[0])
		AND:			stack.push_back(abc[0] && abc[1])
		OR:				stack.push_back(abc[0] || abc[1])
		IS_EQUAL:		stack.push_back(abc[0] == abc[1])
		NOT_EQUAL:		stack.push_back(abc[0] != abc[1])
		MORE_THAN:		stack.push_back(abc[0]  > abc[1])
		MORE_EQUAL:		stack.push_back(abc[0] >= abc[1])
		LESS_THAN:		stack.push_back(abc[0]  < abc[1])
		LESS_EQUAL:		stack.push_back(abc[0] <= abc[1])
		ADD:			stack.push_back(Expr.add(abc[0], abc[1]))
		SUBTRACT:		stack.push_back(Expr.subtract(abc[0], abc[1]))
		MULTIPLY:		stack.push_back(Expr.multiply(abc[0], abc[1]))
		DIVIDE:			stack.push_back(Expr.divide(abc[0], abc[1]))
		MODULO:			stack.push_back(abc[0]  % abc[1])
		BIT_AND:		stack.push_back(abc[0]  & abc[1])
		BIT_OR:			stack.push_back(abc[0]  | abc[1])
		_:				assert(false, "Unimplemented operator type '%s'" % str(type))
