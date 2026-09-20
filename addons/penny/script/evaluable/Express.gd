## Short for "Expression." A series of values and operator_indeces which are evaluated in order. (Like an express train!)
@tool
extends Penny.Evaluable


## Returns the number of symbols to pop from the stack which are needed to completely consume the operator.
static func operator_symbols_required(op: PennyScript.Token.Operator) -> int:
	match op:
		PennyScript.Token.Operator.INVALID, \
		PennyScript.Token.Operator.ARRAY_OPEN, \
		PennyScript.Token.Operator.ARRAY_CLOSE, \
		PennyScript.Token.Operator.ITERATOR:
			return 0

		# PennyScript.Token.Operator.PRESERVE, \
		PennyScript.Token.Operator.NEW, \
		PennyScript.Token.Operator.NOT:
			return 1

		_:
			return 2


## Returns true if the operator is preserved in the expression. Returns false if the operator is weeded out during construction.
static func operator_is_symbol(op: PennyScript.Token.Operator) -> bool:
	match op:
		PennyScript.Token.Operator.INVALID, \
		PennyScript.Token.Operator.GROUP_CLOSE, \
		PennyScript.Token.Operator.GROUP_OPEN, \
		PennyScript.Token.Operator.ARRAY_CLOSE, \
		PennyScript.Token.Operator.ARRAY_OPEN, \
		PennyScript.Token.Operator.ITERATOR, \
		PennyScript.Token.Operator.ARROW_RIGHT, \
		PennyScript.Token.Operator.DOT:
			return false

		_:
			return true


## Given a stack of values, an operator, and a context, reduce the size of the stack by combining elements.
static func operator_apply(stack: Array, op: PennyScript.Token.Operator, context) -> void:
	match op:
		PennyScript.Token.Operator.EVALUATE:
			assert(stack.back() is Penny.Evaluable)
			stack.push_back(stack.pop_back().evaluate(context, Penny.Evaluable.PreserveFlags.PRESERVE_NONE))

	var arg: Array = []
	for i in operator_symbols_required(op):
		arg.push_front(stack.pop_back())

	for i in arg.size():
		arg[i] = Penny.Evaluable.evaluate_any(arg[i], context)

	match op:
		PennyScript.Token.Operator.NEW:
			assert(
				arg[0] is Penny.Cell,
				"The identifiers following 'new' must evaluate to an existing object. Actual value: %s" % [
					arg[0]
				]
			)

			stack.push_back(Penny.Cell.new("", arg[0]))

		PennyScript.Token.Operator.QUESTION:
			stack.push_back(fallback(arg[0], arg[1]))

		PennyScript.Token.Operator.NOT:
			stack.push_back(!arg[0])

		PennyScript.Token.Operator.AND:
			stack.push_back(arg[0] && arg[1])

		PennyScript.Token.Operator.OR:
			stack.push_back(arg[0] || arg[1])

		PennyScript.Token.Operator.IS_EQUAL:
			stack.push_back(arg[0] == arg[1])

		PennyScript.Token.Operator.NOT_EQUAL:
			stack.push_back(arg[0] != arg[1])

		PennyScript.Token.Operator.MORE_THAN:
			stack.push_back(arg[0] > arg[1])

		PennyScript.Token.Operator.MORE_EQUAL:
			stack.push_back(arg[0] >= arg[1])

		PennyScript.Token.Operator.LESS_THAN:
			stack.push_back(arg[0] < arg[1])

		PennyScript.Token.Operator.LESS_EQUAL:
			stack.push_back(arg[0] <= arg[1])

		PennyScript.Token.Operator.ADD:
			stack.push_back(add(arg[0], arg[1]))

		PennyScript.Token.Operator.SUBTRACT:
			stack.push_back(subtract(arg[0], arg[1]))

		PennyScript.Token.Operator.MULTIPLY:
			stack.push_back(multiply(arg[0], arg[1]))

		PennyScript.Token.Operator.DIVIDE:
			stack.push_back(divide(arg[0], arg[1]))

		PennyScript.Token.Operator.MODULO:
			stack.push_back(arg[0] % arg[1])

		PennyScript.Token.Operator.BIT_AND:
			stack.push_back(arg[0] & arg[1])

		PennyScript.Token.Operator.BIT_OR:
			stack.push_back(arg[0] | arg[1])

		_:
			assert(
				false,
				"Unimplemented operator %s" % PennyScript.Token.operator_to_string(op)
			)


static func type_and_value_equals(a, b) -> bool:
	return a == b if typeof(a) == typeof(b) else false


static func add(a, b) -> Variant:
	if a is Array:
		if b is Array:
			a.append_array(b)

		else:
			a.append(b)

		return a

	else:
		return a + b if a != null else +b


static func subtract(a, b) -> Variant:
	if a is Array:
		if b is Array:
			for e in b:
				a.erase(b)

		else:
			a.erase(b)

		return a

	else:
		return a - b if a != null else -b


static func multiply(a, b) -> Variant:
	if a is Array:
		if b is Array:
			var result: Array = []
			for e in b:
				if a.has(e):
					result.push_back(e)
			return result

		else:
			return a.has(b)

	else:
		return a * b


static func divide(a, b) -> Variant:
	if a is Array:
		assert(b is Array)

		var result: Array = []
		for e in b:
			if not a.has(e):
				result.push_back(e)
		return result

	else:
		return a / b


static func fallback(a, b) -> Variant:
	return a if a != null else b


class ExpressConstructor \
extends RefCounted:
	var tokens: Array
	var force_express: bool

	var symbols: Array
	var ops: Array
	var array_depth: int
	var array_stack: Array
	var constant: bool

	func _init(__tokens__: Array, __force_express__: bool) -> void:
		tokens = __tokens__
		force_express = __force_express__

		symbols = []
		ops = []
		array_depth = 0
		array_stack = []
		constant = true


	func operator_encounter(op: PennyScript.Token.Operator) -> bool:
		match op:
			PennyScript.Token.Operator.ARRAY_OPEN:
				symbols.push_back([])
				array_depth += 1
				return true

			PennyScript.Token.Operator.GROUP_OPEN:
				return true

		return false


	## These operators are used when constructing an expression to immediately reduce the stack size.
	func operator_populate(op: PennyScript.Token.Operator) -> void:
		match op:
			PennyScript.Token.Operator.DOT:
				var result : Penny.Path
				match symbols.size():
					0: assert(false, "How did we get here?")
					1: symbols.back().is_relative = true
					_:
						var b = symbols.pop_back()
						var a = symbols.pop_back()

						if a is Penny.Path:
							a.append(b)
							symbols.push_back(a)
						else:
							symbols.push_back(a)
							symbols.push_back(b)
							b.is_relative = true

			PennyScript.Token.Operator.ARROW_RIGHT:
				match symbols.size():
					0:
						assert(false, "How did we get here?")

					1:
						pass
					_:
						var b = symbols.pop_back()
						var a = symbols.pop_back()

						symbols.push_back(Penny.Text.Filter.new(a, b))


	func process() -> Variant:
		for token: PennyScript.Token in tokens:
			if array_depth != 0:
				match token.type:
					PennyScript.Token.Type.OPERATOR:
						match token.value:
							PennyScript.Token.Operator.ARRAY_OPEN:
								array_depth += 1

							PennyScript.Token.Operator.ARRAY_CLOSE:
								array_depth -= 1
								if array_depth != 0:
									array_stack.push_back(token)
									continue

								if array_stack.is_empty():
									continue

								symbols.back().push_back(Penny.Express.new_or_literal_from_tokens_destructive(array_stack))
								array_stack.clear()
								continue

							PennyScript.Token.Operator.ITERATOR:
								if array_stack.is_empty():
									continue

								symbols.back().push_back(Penny.Express.new_or_literal_from_tokens_destructive(array_stack))
								array_stack.clear()
								continue

				array_stack.push_back(token)
				continue


			match token.type:
				PennyScript.Token.Type.LITERAL_BOOLEAN, \
				PennyScript.Token.Type.LITERAL_NUMBER, \
				PennyScript.Token.Type.LITERAL_COLOR, \
				PennyScript.Token.Type.STRING_BLOCK, \
				PennyScript.Token.Type.STRING_QUOTED:
					symbols.push_back(token.value)

				PennyScript.Token.Type.IDENTIFIER:
					symbols.push_back(Penny.Path.new([token.value]))
					constant = false

				PennyScript.Token.Type.OPERATOR:
					var op: PennyScript.Token.Operator = token.value

					if operator_encounter(op):
						continue

					while ops and op <= ops[-1]:
						operator_populate(ops.pop_back())

					ops.push_back(op)

					if Penny.Express.operator_is_symbol(op):
						symbols.push_back(token.duplicate())

				_:
					assert(
						false,
						"Expression from tokens not evaluated: Unexpected token '%s'" % [
							str(token)
						]
					)
					return null

		while ops:
			operator_populate(ops.pop_back())

		var result := Penny.Express.new()
		result.symbols = symbols

		if force_express:
			return result

		match result.symbols.size():
			0:
				return null

			1:
				return symbols[0]

			_ when constant:
				return Penny.Evaluable.evaluate_any(result, null, Penny.Evaluable.PreserveFlags.PRESERVE_PATH)


		return result


@export_storage var symbols: Array


## Creates a new expression from a raw string, by parsing the source String from code to [PennyScript.Token]s.
static func new_or_literal_from_string(source: String, force_express: bool = false) -> Variant:
	var parser := PennyScript.PennyParser.new()
	parser.tokenize(source)

	return new_or_literal_from_tokens_destructive(parser.tokens, force_express)


## Creates a new expression from tokens. If no variables are present, this will return a literal (i.e. it can be used as a constant value).
static func new_or_literal_from_tokens_destructive(tokens: Array, force_express: bool = false) -> Variant:
	var constructor := ExpressConstructor.new(tokens, force_express)
	var result = constructor.process()
	tokens.clear()
	return result


func _to_string() -> String:
	var results : PackedStringArray = []
	for symbol in symbols:
		if symbol is PennyScript.Token:
			match symbol.type:
				PennyScript.Token.Type.OPERATOR:
					results.push_back(PennyScript.Token.operator_to_string(symbol.value))

				PennyScript.Token.Type.IDENTIFIER:
					results.push_back(symbol.value)

		else:
			results.push_back(str(symbol))

	return "$[ %s ]" % [
		" ".join(results),
	]


func _evaluate_single(context) -> Variant:
	var stack: Array = []
	var ops: Array[PennyScript.Token.Operator] = []

	for symbol in symbols:
		if symbol is PennyScript.Token:
			match symbol.type:
				PennyScript.Token.Type.OPERATOR:
					var op : PennyScript.Token.Operator = symbol.value

					while ops and op <= ops[-1]:
						operator_apply(stack, ops.pop_back(), context)

					ops.push_back(op)

				_:
					assert(false, "How did we get here?")

		else:
			stack.push_back(symbol)

	while ops:
		operator_apply(stack, ops.pop_back(), context)

	assert(
		stack.size() == 1,
		"Expression not evaluated: stack size is not exactly 1.\n\tSymbols :: %s\n\tStack :: %s\n\tOperators :: %s" % [
			str(symbols),
			str(stack),
			str(ops)
		]
	)

	return stack[0]
