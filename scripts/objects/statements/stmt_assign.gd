
class_name StmtAssign extends Stmt

func _get_keyword() -> StringName:
	return 'assign'

func _get_verbosity() -> Verbosity:
	return Verbosity.DATA_ACCESS

func _execute(host: PennyHost) -> Record:
	var key : StringName = tokens[0].value
	var before : Variant = host.data.get_data(key)
	var eval = host.evaluate_expression(tokens, 2)
	if eval is PennyObject:
		host.data.add_object(key, tokens[2].value)
	else:
		host.data.set_data(key, eval)
	var after : Variant = host.data.get_data(key)
	return Record.new(host, self, AssignmentRecord.new(key, before, after))

func _undo(record: Record) -> void:
	record.host.data.set_data(record.attachment.key, record.attachment.before)

func _message(record: Record) -> Message:
	return Message.new(record.attachment.to_string())

func _validate() -> PennyException:
	var i_op := -1
	for i in tokens.size():
		if tokens[i].type == Token.ASSIGNMENT:
			i_op = i
			break
	if i_op == -1:
		return create_exception("Expected assignment operator.")
	# var op = tokens[i_op]

	var right := tokens.slice(i_op + 1)
	var right_exception := validate_expression(right)
	if right_exception:
		return right_exception

	return null
