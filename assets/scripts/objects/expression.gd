
class_name Expr extends Evaluable

var stmt : Stmt
var symbols : Array[Variant]


static func new_from_string(string: String, _stmt: Stmt = null) -> Expr:
	return Expr.new_from_tokens(PennyScript.parse_code_to_tokens(string), _stmt)


## Converts raw tokens into workable symbols (Variants).
static func new_from_tokens(tokens: Array, _stmt: Stmt = null) -> Expr:
	var _symbols : Array[Variant] = []
	var ops : Array[Op] = []

	for token in tokens:
		match token.type:
			PennyScript.Token.Type.VALUE_BOOLEAN, \
			PennyScript.Token.Type.VALUE_NUMBER, \
			PennyScript.Token.Type.VALUE_COLOR, \
			PennyScript.Token.Type.VALUE_STRING:
				_symbols.push_back(token.value)
			PennyScript.Token.Type.IDENTIFIER:
				_symbols.push_back(token.value)
			PennyScript.Token.Type.OPERATOR:
				var op : Op = token.value
				if op.type == Op.ITERATOR: continue
				while ops and op.type <= ops.back().type:
					ops.pop_back().apply_init(_symbols)
				match op.type:
					Op.DOT, Op.ARRAY_OPEN, Op.ARRAY_CLOSE:
						ops.push_back(op)
					Op.ITERATOR:
						pass
					_:
						_symbols.push_back(op)
			_:
				printerr("Expression not evaluated: unexpected token '%s'" % token)
				return null

	while ops:
		ops.pop_back().apply_init(_symbols)

	for i in _symbols.size():
		var element = _symbols[i]
		if element is StringName:
			_symbols[i] = Path.new([element], false)

	return Expr.new(_stmt, _symbols)


func _init(_stmt: Stmt, _symbols: Array) -> void:
	stmt = _stmt
	symbols = _symbols


func _to_string() -> String:
	var result := "=> "
	for symbol in symbols:
		result += "%s " % symbol
	return result.substr(0, result.length() - 1)


func _evaluate(context: Cell) -> Variant: return _evaluate_actually(context, false)

## Evaluates the expression, but doesn't evaluate any paths found along the way.
func evaluate_keep_refs(context: Cell) -> Variant: return _evaluate_actually(context, true)

func _evaluate_actually(context: Cell, keep_refs : bool):
	var stack : Array = []
	var ops : Array[Op] = []

	for symbol in symbols:
		if symbol is Op:
			if symbol.type == Op.ITERATOR: continue
			while ops and symbol.type <= ops.back().type:
				ops.pop_back().apply(stack, context, keep_refs)
			ops.push_back(symbol)
		else:
			stack.push_back(symbol)
	while ops:
		ops.pop_back().apply(stack, context, keep_refs)

	if stack.size() != 1:
		printerr("Expression not evaluated: result stack size is not 1. Symbols: %s | Stack: %s" % [str(symbols), str(stack)])
		return null

	return stack[0]



static func type_safe_equals(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	return a == b


class Op extends RefCounted:

	## This order determines the priority in which they are applied, if two or more are encountered in a row (lowest value first).
	enum {
		INVALID,

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

		NEW,
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

		EVALUATE,
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

	var type : int

	var symbols_required : int :
		get:
			match type:
				ARRAY_OPEN, ARRAY_CLOSE, ITERATOR, NEW:
					return 0
				EVALUATE, NOT:
					return 1
				_:
					return 2

	static func _static_init() -> void:
		var s := r""
		for k in PATTERNS.keys():
			s += PATTERNS[k].get_pattern() + "|"
		PATTERN_COMPILED = RegEx.create_from_string(s.substr(0, s.length() - 1))


	static func new_from_string(s: String) -> Op:
		for k in PATTERNS.keys():
			var match : RegExMatch = PATTERNS[k].search(s)
			if match: return Op.new(k)
		return Op.new()


	func _init(_type: int = INVALID) -> void:
		type = _type


	func _to_string() -> String:
		match type:
			GROUP_CLOSE: return ")"
			GROUP_OPEN: return "("
			ARRAY_CLOSE: return "]"
			ARRAY_OPEN: return "["
			ITERATOR: return ","

			IS_EQUAL: return '=='
			NOT_EQUAL: return '!='
			MORE_THAN: return '>'
			MORE_EQUAL: return '>='
			LESS_THAN: return '<'
			LESS_EQUAL: return '<='

			EVALUATE: return "@"
			DOT: return "."
			QUESTION: return "?"

			NEW: return 'new'
			NOT: return '!'
			AND: return '&&'
			OR: return '||'

			ADD: return "+"
			SUBTRACT: return "-"
			MULTIPLY: return "*"
			DIVIDE: return "/"
			MODULO: return "%"
			BIT_AND: return "&"
			BIT_OR: return "|"
		return "INVALID_OP"


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


	func apply(stack: Array[Variant], context: Cell, force_paths := false) -> void:
		match type:
			NEW:
				var data : Dictionary[StringName, Variant] = {}
				if stack:
					data[Cell.K_PROTOTYPE] = stack.pop_back()
				else:
					data[Cell.K_PROTOTYPE] = Path.DEFAULT_BASE
				stack.push_back(Cell.new(Cell.NEW_OBJECT_KEY_NAME, context, data))
				return

		var abc : Array[Variant] = []
		for i in symbols_required:
			abc.push_front(stack.pop_back())

		if force_paths:
			pass
		else: for i in abc.size():
			var e = abc[i]
			if e is Evaluable:
				abc[i] = e.evaluate(context)

		match type:
			EVALUATE:		stack.push_back(abc[0].evaluate(context))
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
			ADD:			stack.push_back(abc[0]  + abc[1])
			SUBTRACT:		stack.push_back(abc[0]  - abc[1])
			MULTIPLY:		stack.push_back(abc[0]  * abc[1])
			DIVIDE:			stack.push_back(abc[0]  / abc[1])
			MODULO:			stack.push_back(abc[0]  % abc[1])
			BIT_AND:		stack.push_back(abc[0]  & abc[1])
			BIT_OR:			stack.push_back(abc[0]  | abc[1])
			_:				printerr("Unimplemented operator type %s" % str(type))