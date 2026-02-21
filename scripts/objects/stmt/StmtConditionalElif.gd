class_name StmtConditionalElif extends StmtConditional

func _evaluate_self(host: PennyHost) -> Variant:
	## May return TRUE, FALSE, or NULL
	if host.expecting_conditional:
		return self.expr.evaluate()
	return null
