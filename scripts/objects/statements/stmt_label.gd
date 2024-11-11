
## Speaks nothing. Hears nothing. Sees nothing. Is nothing.
class_name StmtLabel extends Stmt


# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return "label"


func _get_verbosity() -> int:
	return Verbosity.IGNORED


func _validate_self() -> PennyException:
	return validate_as_identifier_only()


# func _validate_self_post_setup() -> void:
# 	pass

func _validate_cross() -> PennyException:
	if Penny.labels.has(tokens[0].value):
		return create_exception("Label '%s' already exists (%s)" % [tokens[0].value, Penny.get_stmt_from_label(tokens[0].value).file_address.pretty_string])
	else:
		Penny.labels[tokens[0].value] = self
		return super._validate_cross()


# func _undo(record: Record) -> void:
# 	pass


# func _next(record: Record) -> Stmt:
# 	return next_in_order
