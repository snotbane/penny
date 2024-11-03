
## No description
class_name StmtMatch extends StmtExpr_

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'match'


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


# func _validate_self() -> PennyException:
# 	return validate_as_expression()


# func _validate_self_post_setup() -> void:
# 	super._validate_self_post_setup()


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


func _execute(host: PennyHost) -> Record:
	host.expecting_conditional = true
	return super._execute(host)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt_:
# 	return super._next(record)
