
class_name StmtAssign extends StmtCell

var expr: Expr

func _populate(tokens: Array) -> void:
	var op_index := -1
	for i in tokens.size():
		if tokens[i].type == PennyScript.Token.Type.ASSIGNMENT:
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
	var prior : Variant = subject
	var after : Variant = expr.evaluate(context)
	if after is Cell:
		after.key_name = subject_ref.ids[subject_ref.ids.size() - 1]
	subject_ref.set_local_value_in_cell(self.context, after)

	# print({ &"ref": subject_ref.globalize(self.context), &"prior": prior, &"after": after })

	return create_record(host, { &"prior": prior, &"after": after })