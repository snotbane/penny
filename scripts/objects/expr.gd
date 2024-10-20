
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

	var symbols_required : int :
		get:
			match type:
				DEREF, LOOKUP, NOT:
					return 1
				_:
					return 2

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

	func apply(stack: Array[Variant], host: PennyHost) -> void:
		var abc : Array[Variant] = []
		for i in symbols_required:
			abc.push_front(stack.pop_back())
		# match type:
		# 	# LOOKUP:
		# 	# 	if host:
		# 	# 		host.
		# 	# 	else:
		# 	# 		stack.push_back(Lookup.new(abc[0]))
		# 	DEREF:
		# 		stack.push_back(abc[0].get_data(host))
		# 		return

		for i in abc.size():
			var e = abc[i]
			if e is Expr:
				abc[i] = e.evaluate(host)
			if e is Path:
				abc[i] = e.get_data(host)

		match type:
			NOT:			stack.push_back(not abc[0])
			AND:			stack.push_back(abc[0] and abc[1])
			OR:				stack.push_back(abc[0] or abc[1])
			IS_EQUAL:		stack.push_back(abc[0] == abc[1])
			NOT_EQUAL:		stack.push_back(abc[0] != abc[1])

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

var returns_self_softly : bool :
	get:
		if symbols.size() == 1: return false
		var path_count := 0
		var deref_count := 0
		for symbol in symbols:
			if symbol is Path:
				path_count += 1
			elif symbol is Op and symbol.type == Op.DEREF:
				deref_count += 1
		return deref_count < path_count

func _init(_stmt: Stmt_, _symbols: Array) -> void:
	stmt = _stmt
	symbols = _symbols

## Converts raw tokens into workable symbols (Variants).
static func from_tokens(_stmt: Stmt_, tokens: Array[Token]) -> Expr:
	var stack : Array[Variant] = []
	var ops : Array[Op] = []

	for token in tokens:
		match token.type:
			Token.VALUE_BOOLEAN, Token.VALUE_NUMBER, Token.VALUE_COLOR, Token.VALUE_STRING:
				stack.push_back(token.value)
			Token.IDENTIFIER:
				stack.push_back(token.value)
			Token.OPERATOR:
				var op := Op.new(token.value)
				while ops and op.type > ops.back().type:
					ops.pop_back().apply_static(stack)
				match op.type:
					Op.LOOKUP, Op.DOT:
						ops.push_back(op)
					_:
						stack.push_back(op)
			_:
				_stmt.create_exception("Expression not evaluated: unexpected token '%s'" % token)
				return null

	while ops:
		ops.pop_back().apply_static(stack)

	for i in stack.size():
		var element = stack[i]
		if element is StringName:
			stack[i] = Path.new([element], false)

	return Expr.new(_stmt, stack)


func _to_string() -> String:
	var result := ""
	for symbol in symbols:
		result += str(symbol) + " "
	return result.substr(0, result.length() - 1)

func evaluate(host: PennyHost, soft: bool = false) -> Variant:
	if returns_self_softly: return self

	var stack : Array[Variant] = []
	var ops : Array[Op] = []

	for symbol in symbols:
		# if symbol is Expr:
		# 	stack.push_back(symbol.evaluate(soft))
		if symbol is Op:
			while ops and symbol.type > ops.back().type:
				ops.pop_back().apply(stack, host)
			ops.push_back(symbol)
		else:
			stack.push_back(symbol)

	while ops:
		ops.pop_back().apply(stack, host)

	if stack.size() != 1:
		stmt.create_exception("Expression not evaluated: stack size is not 1. Symbols: %s | Stack: %s" % [str(symbols), str(stack)])
		return null

	if stack[0] == null:
		stmt.create_exception("Expression evaluated to null.")
		return null

	if stack[0] is StringName:
		return Path.new([stack[0]])

	return stack[0]
