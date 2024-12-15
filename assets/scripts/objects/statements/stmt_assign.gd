
class_name StmtAssign extends StmtObject

var expr : Expr

var op_index : int = -1
var expression_index : int :
	get: return op_index + 1


# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'assign'


func _get_verbosity() -> Verbosity:
	return Verbosity.DATA_ACTIVITY


func _validate_self() -> PennyException:
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

	path = Path.new_from_tokens(left)
	expr = Expr.from_tokens(right, self)
	return null


func _execute(host: PennyHost) :
	var prior : Variant = path.evaluate_shallow(self.owning_object)
	var after : Variant = expr.evaluate_shallow(self.owning_object)
	if after is PennyObject:
		after.self_key = path.ids.back()

	path.set_value_for(self.owning_object, after)

	return create_assignment_record(host, prior, after)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt:
# 	return next_in_order
