
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
var expr: Expr

func _get_verbosity() -> Verbosity:
	return Verbosity.DATA_ACTIVITY

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
					printerr("Invalid assignment type '%s'" % tokens[i].value)
			op_index = i
			break

	if op_index == -1:
		printerr("Expected assignment operator.")
		return

	var expr_index := op_index + 1
	if expr_index >= tokens.size():
		printerr("Expected expression after assignment operator.")
		return

	var left := tokens.slice(0, op_index)
	local_subject_ref = Cell.Ref.new_from_tokens(left)

	var right := tokens.slice(expr_index)
	expr = Expr.new_from_tokens(right, self)


func _execute(host: PennyHost) :
	var prior : Variant = local_subject_ref.evaluate_local(context)
	var after : Variant

	match type:
		Type.EXPRESSION:	after = expr
		Type.FLAT:			after = expr.evaluate_keep_refs(context)
		Type.ADD:			after = prior + expr.evaluate_keep_refs(context)
		Type.SUBTRACT:		after = prior - expr.evaluate_keep_refs(context)
		Type.MULTIPLY:		after = prior * expr.evaluate_keep_refs(context)
		Type.DIVIDE:		after = prior / expr.evaluate_keep_refs(context)

	if after is Cell:
		if after.key_name == Cell.NEW_OBJECT_KEY_NAME:
			after.key_name = subject_ref.ids[subject_ref.ids.size() - 1]
		else:
			after = Cell.Ref.to(after)
	subject_ref.set_local_value_in_cell(self.context, after)

	# print({ &"ref": subject_ref.globalize(self.context), &"prior": prior, &"after": after })

	return create_record(host, { &"prior": prior, &"after": after })


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]assign %s : [color=slate_gray]%s[/color] => [color=dodger_blue]%s[/color][/color][/code]" % [Penny.get_value_as_bbcode_string(subject_ref), Penny.get_value_as_bbcode_string(record.data[&"prior"]), Penny.get_value_as_bbcode_string(record.data[&"after"])]