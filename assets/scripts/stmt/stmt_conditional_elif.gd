
## No description
class_name StmtConditionalElif extends StmtConditional


# func _validate_cross() -> PennyException:
# 	if not (prev_in_same_depth is StmtConditionalIf or prev_in_same_depth is StmtConditionalElif):
# 		return create_exception("Expected if or elif before elif statement")
# 	return null


func _evaluate_self(host: PennyHost) -> Variant:
	## May return TRUE, FALSE, or NULL
	if host.expecting_conditional:
		return self.expr.evaluate()
	return null


func _should_passover(record: Record) -> bool:
	return not (record.host.expecting_conditional and record.data)
