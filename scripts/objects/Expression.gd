
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
				assert(false, "Expression not evaluated: unexpected token '%s'" % token)
				return null

	while ops:
		ops.pop_back().apply_init(_symbols)

	for i in _symbols.size():
		var element = _symbols[i]
		if element is StringName:
			_symbols[i] = Path.new([element], false)

	return Expr.new(_stmt, _symbols)


static func add(a: Variant, b: Variant) -> Variant:
	if a is Array:
		if b is Array:	a.append_array(b)
		else:			a.append(b)
		return a
	else:
		return a + b if a != null else +b

static func subtract(a: Variant, b: Variant) -> Variant:
	if a is Array:
		if b is Array: for e in b:	a.erase(e)
		else:						a.erase(b)
		return a
	else:
		return a - b if a != null else -b

static func multiply(a: Variant, b: Variant) -> Variant:
	if a is Array:
		if b is Array:
			var result : Array = []
			for e in b: if a.has(e): result.push_back(e)
			return result
		else:
			return a.has(b)
	else:
		return a * b

static func divide(a: Variant, b: Variant) -> Variant:
	if a is Array:
		assert(b is Array, "")

		var result : Array = []
		for e in b: if not a.has(e): result.push_back(e)
		return result
	else:
		return a / b


func _init(_stmt: Stmt = null, _symbols: Array = []) -> void:
	stmt = _stmt
	symbols = _symbols


func _to_string() -> String:
	var result := "=> "
	for symbol in symbols:
		result += "%s " % symbol
	return result.substr(0, result.length() - 1)


func export_json() -> Variant:
	return JSONSerialize.serialize(symbols)
	# var result := "=> "
	# for symbol in symbols:
	# 	result += "%s " % symbol.export_json() if symbol is Object and symbol.has_method(&"export_json") else symbol
	# return result.substr(0, result.length() - 1)

func import_json(json: Variant) -> void:
	symbols = JSONSerialize.deserialize(json)
	# symbols = Expr.new_from_string(json).symbols


func _evaluate(context: Cell) -> Variant:
	var stack : Array = []
	var ops : Array[Op] = []

	for symbol in symbols:
		if symbol is Op:
			if symbol.type == Op.ITERATOR: continue
			while ops and symbol.type <= ops.back().type:
				ops.pop_back().apply(stack, context)
			ops.push_back(symbol)
		else:
			stack.push_back(symbol)
	while ops:
		ops.pop_back().apply(stack, context)

	assert(stack.size() == 1, "Expression not evaluated: result stack size is not 1. Symbols: %s | Stack: %s" % [str(symbols), str(stack)])

	return stack[0]


static func type_safe_equals(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	return a == b
