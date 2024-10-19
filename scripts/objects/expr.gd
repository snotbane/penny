
class_name Expr extends RefCounted

class Op extends RefCounted:
	enum {
		INVALID,
		DEREF,				# @
		LOOKUP,				# $
		NOT,				# !  , not
		AND,				# && , and
		OR,					# || , or
		IS_EQUAL,			# ==
		NOT_EQUAL,			# !=
		DOT,				# .
		QUESTION,			# ?
	}

	var type : int

	func _init(key: StringName) -> void:
		match key:
			'!', 'not': 	type = NOT
			'$': 			type = LOOKUP
			'&&', 'and': 	type = AND
			'||', 'or': 	type = OR
			'==': 			type = IS_EQUAL
			'!=': 			type = NOT_EQUAL
			'.': 			type = DOT
			'@': 			type = DEREF
			'?': 			type = QUESTION
			_ :				type = INVALID

	func _to_string() -> String:
		match type:
			NOT: return 'not'
			LOOKUP: return '$'
			AND: return 'and'
			OR: return 'or'
			IS_EQUAL: return '=='
			NOT_EQUAL: return '!='
			DOT: return '.'
			DEREF: return '@'
			QUESTION: return '?'
		return 'INVALID_OP'

	func apply(stack: Array[Variant]) -> void:
		match type:
			NOT:			stack.push_back(not stack.pop_back())
			AND:			stack.push_back(stack.pop_back() and stack.pop_back())
			OR:				stack.push_back(stack.pop_back() or stack.pop_back())
			IS_EQUAL:		stack.push_back(stack.pop_back() == stack.pop_back())
			NOT_EQUAL:		stack.push_back(stack.pop_back() != stack.pop_back())
		pass

	func apply_static(stack: Array[Variant]) -> void:
		match type:
			LOOKUP:
				stack.push_back(Lookup.new(stack.pop_back()))
			DOT:
				match stack.size():
					1:
						stack.push_back(Path.new([stack.pop_back()], true))
					_:
						var b = stack.pop_back()
						var a = stack.pop_back()
						if a is Path:
							a.identifiers.push_back(b)
							stack.push_back(a)
						elif a is StringName:
							stack.push_back(Path.new([a, b], false))
						else:
							stack.push_back(a)
							stack.push_back(Path.new([b], true))

var stmt : Stmt_
var symbols : Array[Variant]

func _init(_stmt: Stmt_, _symbols: Array) -> void:
	stmt = _stmt
	symbols = _symbols

## Converts raw tokens into workable symbols (Variants). Weeds out a few operators along the way.
static func from_tokens(_stmt: Stmt_, tokens: Array[Token]) -> Expr:
	var stack : Array[Variant] = []
	var ops : Array[Op] = []

	for token in tokens:
		match token.type:
			Token.VALUE_BOOLEAN, Token.VALUE_NUMBER, Token.VALUE_COLOR, Token.VALUE_STRING:
				stack.push_back(token.value)
			Token.IDENTIFIER:
				stack.push_back(StringName(token.value))
			Token.OPERATOR:
				var op := Op.new(token.value)
				stack.push_back(op)
				# while ops and op.type <= ops.back().type:
				# 	ops.pop_back().apply(stack)
				# match op.type:
				# 	Op.DOT, Op.LOOKUP:
				# 		ops.push_back(op)
				# 	_:
				# 		stack.push_back(op)
			_:
				_stmt.create_exception("Expression not evaluated: unexpected token '%i'" % token)
				return null

	while ops:
		ops.pop_back().apply(stack)

	return Expr.new(_stmt, stack)

static func create_or_evaluate_from_tokens(_stmt: Stmt_, tokens: Array[Token]) -> Variant:
	var expr := from_tokens(_stmt, tokens)
	print(expr.symbols)
	for i in expr.symbols:
		if i is Path:
			return expr
	return expr.evaluate(null)

func _to_string() -> String:
	return "Expr: %s" % str(symbols)

func evaluate(host: PennyHost, soft := false) -> Variant:
	var stack : Array[Variant] = []
	var ops : Array[Op] = []
	var contains_paths := false

	for symbol in symbols:
		if symbol is Path:
			var path = symbol as Path
			contains_paths = true
			stack.push_back(symbol)
		else:
			stack.push_back(symbol)

	if soft and contains_paths:
		return self
	while ops:
		apply_operator(stack, ops.pop_back())

	if stack.size() != 1:
		stmt.create_exception("Expression not evaluated: stack size is not 1. Symbols: %s | Stack: %s" % [str(symbols), str(stack)])
		return null

	if stack[0] is StringName:
		return Path.new([stack[0]])

	return stack[0]

func apply_operator(stack: Array[Variant], op: Token, soft := false) -> void:
	var token_count := op.get_operator_token_count()
	match token_count:
		-1: return
		0:	token_count = stack.size()

	var abc : Array[Variant] = []
	for i in op.get_operator_token_count():
		abc.push_front(stack.pop_back())

	match op.get_operator_type():
		Token.Operator.NOT:			stack.push_back(not abc[0])
		Token.Operator.LOOKUP:		stack.push_back(Lookup.new(abc[0]))
		Token.Operator.AND:			stack.push_back(abc[0] and abc[1])
		Token.Operator.OR:			stack.push_back(abc[0] or abc[1])
		Token.Operator.IS_EQUAL:	stack.push_back(abc[0] == abc[1])
		Token.Operator.NOT_EQUAL:	stack.push_back(abc[0] != abc[1])
		Token.Operator.DOT:
			var path : Path
			if abc.size() == 1:
				var nest := stmt.nested_object_stmt
				path = nest.path.get_absolute_path(nest)
			elif abc[0] is Path:
				path = abc[0]
			else:
				path = Path.new([abc[0]])
			path.identifiers.push_back(abc[1])
			stack.push_back(path)

func validate() -> PennyException:
	return null
