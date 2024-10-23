
class_name StmtAssign extends StmtObject_

var expr : Expr

var op_index : int = -1
var expression_index : int :
	get: return op_index + 1

func _get_keyword() -> StringName:
	return 'assign'

func _get_verbosity() -> Verbosity:
	return Verbosity.DATA_ACTIVITY

func _execute(host: PennyHost) -> Record:
	var before : Variant = path.evaluate(host)
	var after : Variant = expr.evaluate(host, true)
	if after == null:
		create_exception("Couldn't assign '%s' using '%s' because it evaluated to null." % [path, expr]).push()
	elif after is PennyObject and after == PennyObject.BILTIN_OBJECT:
		after = path.add_object(host)
	else:
		path.set_data(host, after)
	return create_record(host, before, after)

# func _undo(record: Record) -> void:
# 	super._undo(record)

# func _message(record: Record) -> Message:
# 	return super._message(record)

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
	var left_exception := validate_path(left)
	if left_exception:
		return left_exception

	var right := tokens.slice(expression_index)
	var right_exception := validate_expression(right)
	if right_exception:
		return right_exception

	path = Path.from_tokens(left)
	expr = Expr.from_tokens(self, right)
	return null
