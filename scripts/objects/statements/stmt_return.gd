
## No description
class_name StmtReturn extends Stmt

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'return'


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _validate_self() -> PennyException:
	return null


# func _validate_self_post_setup() -> void:
# 	pass


# func _validate_cross() -> PennyException:
# 	return null


func _execute(host: PennyHost) -> Record:
	return super._execute(host)


# func _undo(record: Record) -> void:
# 	pass


func _next(record: Record) -> Stmt:
	return null
