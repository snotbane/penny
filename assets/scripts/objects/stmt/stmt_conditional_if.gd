
## No description
class_name StmtConditionalIf extends StmtConditional


func _evaluate_self(host: PennyHost) -> Variant:
	## Always returns TRUE or FALSE
	return self.expr.evaluate()


func _should_passover(record: Record) -> bool:
	return not record.data

