
## No description
class_name StmtJump extends StmtExpr


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _populate(tokens: Array) -> void:
	tokens.pop_front()
	super._populate(tokens)


func _execute(host: PennyHost) :
	var label_name : StringName = expr.evaluate()
	return self.create_record(host, label_name)


# func _undo(record: Record) -> void:
# 	pass


func _next(record: Record) -> Stmt:
	return Penny.get_stmt_from_label(record.data)
