extends StmtConditional
class_name StmtConditionalIf


func _evaluate_self(host: PennyHost) -> Variant:
	## Always returns TRUE or FALSE
	return self.expr.evaluate()


func _should_pass_over(record: Record) -> bool:
	return not record.data[&"result"]

