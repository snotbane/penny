
## No description
class_name StmtJump extends Stmt_


func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)


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


func _execute(host: PennyHost) -> Record:
	var label = tokens[0].value
	return create_record(host, false, label)


# func _undo(record: Record) -> void:
# 	pass


func _next(record: Record) -> Stmt_:
	print("Jumping to ", record.attachment)
	return Penny.get_stmt_from_label(record.attachment)


# func _message(record: Record) -> Message:
# 	return super._message(record)
