
## No description
class_name StmtJump extends Stmt


# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'jump'


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _validate_self() -> PennyException:
	return validate_as_expression()


# func _validate_self_post_setup() -> void:
# 	pass


# func _validate_cross() -> PennyException:
# 	return null


func _execute(host: PennyHost) :
	var label = tokens[0].value
	return create_record(host, label)


# func _undo(record: Record) -> void:
# 	pass


func _next(record: Record) -> Stmt:
	print("Jumping to ", record.attachment)
	return Penny.get_stmt_from_label(record.attachment)
