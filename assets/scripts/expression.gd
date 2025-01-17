
class_name Expr extends Evaluable

var stmt : Stmt
var symbols : Array[Variant]

func _init(_stmt: Stmt, _symbols: Array) -> void:
	stmt = _stmt
	symbols = _symbols

static func from_string(string: String, _stmt: Stmt = null) -> Expr:
	return Expr.from_tokens(PennyScript.parse_code_to_tokens(string), _stmt)


## Converts raw tokens into workable symbols (Variants).
static func from_tokens(tokens: Array, _stmt: Stmt = null) -> Expr:
	var stack : Array[Variant] = []
	# var ops : Array[PennyScript.Op] = []

	# for token in tokens:
	# 	match token.type:
	# 		PennyScript.Token.Type.VALUE_BOOLEAN, \
	# 		PennyScript.Token.Type.VALUE_NUMBER, \
	# 		PennyScript.Token.Type.VALUE_COLOR, \
	# 		PennyScript.Token.Type.VALUE_STRING:
	# 			stack.push_back(token.value)
	# 		PennyScript.Token.Type.IDENTIFIER:
	# 			stack.push_back(token.value)
	# 		PennyScript.Token.Type.OPERATOR:
	# 			if token.value == ',': continue
	# 			var op := Op.new(token.value)
	# 			while ops and op.type <= ops.back().type:
	# 				ops.pop_back().apply_static(stack)
	# 			match op.type:
	# 				Op.LOOKUP, Op.DOT, Op.ARRAY_OPEN, Op.ARRAY_CLOSE:
	# 					ops.push_back(op)
	# 				Op.ITERATOR:
	# 					pass
	# 				_:
	# 					stack.push_back(op)
	# 		_:
	# 			if _stmt:
	# 				_stmt.push_exception("Expression not evaluated: unexpected token '%s'" % token)
	# 			else:
	# 				PennyException.new("Expression not evaluated: unexpected token '%s'" % token).push_error()
	# 			return null

	# while ops:
	# 	ops.pop_back().apply_static(stack)

	# for i in stack.size():
	# 	var element = stack[i]
	# 	if element is StringName:
	# 		stack[i] = Path.new([element], false)

	return Expr.new(_stmt, stack)


func _to_string() -> String:
	var result := "=> "
	for symbol in symbols:
		result += "%s " % symbol
	return result.substr(0, result.length() - 1)


func _evaluate(context: Cell) -> Variant:
	return null
	# var stack : Array[Variant] = []
	# var ops : Array[Op] = []

	# for symbol in symbols:
	# 	if symbol is Op:
	# 		if symbol.type == Op.ITERATOR: continue
	# 		while ops and symbol.type <= ops.back().type:
	# 			ops.pop_back().apply(stack, context)
	# 		ops.push_back(symbol)
	# 	else:
	# 		stack.push_back(symbol)
	# while ops:
	# 	ops.pop_back().apply(stack, context)

	# if stack.size() != 1:
	# 	PennyException.new("Expression not evaluated: stack size is not 1. Symbols: %s | Stack: %s" % [str(symbols), str(stack)]).push_error()
	# 	return null
	# var result = stack.pop_back()
	# # if result == null:
	# # 	PennyException.new("Expression '%s' evaluated to null." % self).push_warn()
	# # 	return null

	# return result


static func type_safe_equals(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	return a == b