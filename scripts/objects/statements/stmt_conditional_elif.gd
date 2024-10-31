
## No description
class_name StmtConditionalElif extends StmtConditional_


# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return super._get_keyword() + ' elif'


# func _validate_self() -> PennyException:
# 	return validate_as_expression()


# func _validate_self_post_setup() -> void:
# 	super._validate_self_post_setup()


func _validate_cross() -> PennyException:
	if not (prev_in_same_depth is StmtConditionalIf or prev_in_same_depth is StmtConditionalElif):
		return create_exception("Expected if or elif before elif statement")
	return null


func _evaluate_self(host: PennyHost) -> Variant:
	## May return TRUE, FALSE, or NULL
	if host.expecting_conditional:
		return self.expr.evaluate(host.data_root)
	return null


func _should_skip(record: Record) -> bool:
	return not (record.host.expecting_conditional and record.attachment)
