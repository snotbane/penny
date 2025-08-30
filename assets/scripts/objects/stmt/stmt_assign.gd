## Assigns the local value of a [Cell] to a specified value.
class_name StmtAssign extends StmtCell

enum Type {
	INVALID,
	EXPRESSION,
	FLAT,
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
}

var type : Type
var expr : Expr

func _get_verbosity() -> Verbosity:
	return Verbosity.DATA_ACTIVITY

func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]assign %s : [color=slate_gray]%s[/color] => [color=dodger_blue]%s[/color][/color][/code]" % [Penny.get_value_as_bbcode_string(subject_ref), Penny.get_value_as_bbcode_string(record.data[&"prior"]), Penny.get_value_as_bbcode_string(record.data[&"after"])]


# func _init(__storage_qualifier__ := StorageQualifier.NONE) -> void:
# 	super._init(__storage_qualifier__)

func _populate(tokens: Array) -> void:
	var op_index := -1
	for i in tokens.size():
		if tokens[i].type == PennyScript.Token.Type.ASSIGNMENT:
			match tokens[i].value:
				"=>": 	type = Type.EXPRESSION
				"=": 	type = Type.FLAT
				"+=": 	type = Type.ADD
				"-=": 	type = Type.SUBTRACT
				"*=": 	type = Type.MULTIPLY
				"/=": 	type = Type.DIVIDE
				_:
						type = Type.INVALID
						assert(false, "Invalid assignment type '%s'" % tokens[i].value)
			op_index = i
			break

	assert(op_index != -1, "Expected assignment operator.")

	var expr_index := op_index + 1
	assert(expr_index < tokens.size(), "Expected expression after assignment operator.")

	var left := tokens.slice(0, op_index)
	local_subject_ref = Path.new_from_tokens(left)

	var right := tokens.slice(expr_index)
	expr = Expr.new_from_tokens(right, self)

func _prep(record: Record) -> void:
	super._prep(record)

	var prior : Variant = local_subject_ref.evaluate_local(context)
	var after : Variant

	match type:
		Type.EXPRESSION:	after = expr
		Type.FLAT:			after = expr._evaluate(context)						## Use [_evaluate] here so that raw paths will be preserved. [Expr] will automatically evaluate [Path]s if needed.
		_:
			assert(prior != null, "Can't operate on a null value.")
			var eval = expr.evaluate(context)
			match type:
				Type.ADD:		after = Expr.add(prior, eval)
				Type.SUBTRACT:	after = Expr.subtract(prior, eval)
				Type.MULTIPLY:	after = Expr.multiply(prior, eval)
				Type.DIVIDE:	after = Expr.divide(prior, eval)

	if after is Cell:
		if after.key_name == Cell.NEW_OBJECT_KEY_NAME:
			after.key_name = subject_ref.ids[subject_ref.ids.size() - 1]
		else:
			after = Path.to(after)
	subject_ref.set_local_value_in_cell(self.context, after)

	# print({ &"ref": subject_ref.globalize(self.context), &"prior": prior, &"after": after })

	record.data.merge({
		&"prior": Path.to(prior) if prior is Cell else prior,
		&"after": Path.to(after) if after is Cell else after
	})

func _undo(record: Record) -> void:
	subject_ref.set_local_value_in_cell(context, record.data[&"prior"])
	super._undo(record)

func _redo(record: Record) -> void:
	subject_ref.set_local_value_in_cell(context, record.data[&"after"])
	super._redo(record)
