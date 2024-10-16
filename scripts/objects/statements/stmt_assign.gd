
class_name StmtAssign extends StmtObject_

var op_index : int = -1
var expression_index : int :
	get: return op_index + 1

func _get_keyword() -> StringName:
	return 'assign'

func _get_verbosity() -> Verbosity:
	return Verbosity.DATA_ACCESS

func _execute(host: PennyHost) -> Record:
	var before : Variant = obj_path.get_data(host)
	var after : Variant = host.evaluate_expression(tokens, expression_index)
	if after is PennyObject and after == PennyObject.DEFAULT_OBJECT:
		after = obj_path.add_object(host)
	obj_path.set_data(host, after)
	return Record.new(host, self, AssignmentRecord.new(before, after))

func _undo(record: Record) -> void:
	obj_path.set_data(record.host, record.attachment.before)

func _message(record: Record) -> Message:
	var result := super._message(record)
	result.append(" = %s" % record.attachment)
	return result

func _validate() -> PennyException:
	op_index = -1
	for i in tokens.size():
		if tokens[i].type == Token.ASSIGNMENT:
			op_index = i
			break
	if op_index == -1:
		return create_exception("Expected assignment operator.")
	if expression_index >= tokens.size():
		return create_exception("Expected expression after assignment operator.")
	# var op = tokens[i_op]

	var left := tokens.slice(0, op_index)
	var left_exception := validate_obj_path(left)
	if left_exception:
		return left_exception

	var right := tokens.slice(expression_index)
	var right_exception := validate_expression(right)
	if right_exception:
		return right_exception

	obj_path = ObjectPath.from_tokens(left)
	return null
