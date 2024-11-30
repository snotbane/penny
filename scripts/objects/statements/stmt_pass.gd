
## Speaks nothing. Hears nothing. Sees nothing. Is nothing.
class_name StmtPass extends Stmt

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return "pass"


func _get_verbosity() -> Verbosity:
	return Verbosity.IGNORED


func _validate_self() -> PennyException:
	return validate_as_no_tokens()


# func _validate_self_post_setup() -> void:
# 	pass


# func _validate_cross() -> PennyException:
# 	return null


func _execute(host: PennyHost) :
	return super._execute(host)


# func _undo(record: Record) -> void:
# 	pass


# func _next(record: Record) -> Stmt:
# 	return next_in_order
