
class_name StmtConditional extends StmtExpr


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _execute(host: PennyHost) :
	return self.create_record(host, _evaluate_self(host))


func _next(record: Record) -> Stmt:
	if record.data == null:
		record.host.expecting_conditional = false
		return next_in_same_or_lower_depth

	var passover := _should_passover(record)

	var result : Stmt
	if passover: 	result = next_in_same_depth
	else:		result = next_in_order

	if result:
		record.host.expecting_conditional = passover and result is StmtConditional
		return result
	else:
		record.host.expecting_conditional = false
		return next_in_same_or_lower_depth


func _evaluate_self(host: PennyHost) -> Variant: return null


func _should_passover(record: Record) -> bool: return true


func _get_record_message(record: Record) -> String:
	match record.data:
		true:
			return "[code][color=lawn_green]PASSED[/color][/code]"
		false:
			return "[code][color=deep_pink]FAILED[/color][/code]"
		_:
			return "[s]%s [code][color=dim_gray]SKIPPED[/color][/code]"