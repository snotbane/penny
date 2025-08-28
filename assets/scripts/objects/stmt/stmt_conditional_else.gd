class_name StmtConditionalElse extends StmtConditional

func _evaluate_self(host: PennyHost) -> Variant:
	## Always return TRUE or NULL
	if host.expecting_conditional:
		return true
	return null

func _should_pass_over(record: Record) -> bool:
	return not record.host.expecting_conditional
