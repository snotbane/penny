
## Speaks nothing. Hears nothing. Sees nothing. Is nothing.
class_name StmtLabel extends Stmt

var id : StringName

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return "label"


func _get_verbosity() -> int:
	return Verbosity.IGNORED


func _validate_self() -> PennyException:
	return validate_as_identifier_only()


func _validate_self_post_setup() -> void:
	self.id = tokens[0].value


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


# func _undo(record: Record) -> void:
# 	pass


# func _next(record: Record) -> Stmt:
# 	return next_in_order
