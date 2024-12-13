
## No description
class_name StmtNew extends Stmt

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return super._get_keyword()


func _get_verbosity() -> Verbosity:
	return super._get_verbosity()


# func _get_is_roll_point() -> bool:
# 	return true


func _validate_self() -> PennyException:
	return create_exception("Statement was registered/recognized, but _validate_self() was not overridden!")


# func _validate_self_post_setup() -> void:
# 	super._validate_self_post_setup()


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


func _execute(host: PennyHost) :
	return super._execute(host)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt:
# 	return super._next(record)
