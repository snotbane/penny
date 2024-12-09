
## No description
class_name StmtConditionalIf extends StmtConditional


# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return super._get_keyword() + ' if'


# func _validate_self() -> PennyException:
# 	return validate_as_expression()


func _evaluate_self(host: PennyHost) -> Variant:
	## Always returns TRUE or FALSE
	return self.expr.evaluate()


func _should_passover(record: Record) -> bool:
	return not record.attachment

