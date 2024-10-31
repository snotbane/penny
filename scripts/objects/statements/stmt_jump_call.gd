
## No description
class_name StmtJumpCall extends StmtJump

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'call'


# func _get_verbosity() -> Verbosity:
# 	return super._get_verbosity()


func _validate_self() -> PennyException:
	return super._validate_self()


# func _validate_self_post_setup() -> void:
# 	pass


# func _validate_cross() -> PennyException:
# 	return null


func _execute(host: PennyHost) -> Record:
	host.call_stack.push_back(next_in_order)
	return super._execute(host)


func _undo(record: Record) -> void:
	record.host.call_stack.pop_back()


# func _next(record: Record) -> Stmt_:
# 	return next_in_order


func _message(record: Record) -> Message:
	return super._message(record)
