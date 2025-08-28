## Base class for the header of a conditional branch. [Stmt]s belonging to this branch may or may not be called, depending on the environment, or user interactions.
class_name StmtConditional extends StmtExpr

func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY

func _get_record_message(record: Record) -> String:
	match record.data:
		true:
			return "[code][color=lawn_green]PASSED[/color][/code]"
		false:
			return "[code][color=deep_pink]FAILED[/color][/code]"
		_:
			return "[s]%s [code][color=dim_gray]SKIPPED[/color][/code]"


func _prep(record: Record) -> void:
	record.data.merge({
		&"result": _evaluate_self(record.host)
	})

func _next(record: Record) -> Stmt:
	if record.data[&"result"] == null:
		record.host.expecting_conditional = false
		return next_in_same_or_lower_depth

	var pass_over := _should_pass_over(record)
	var result : Stmt = next_in_same_depth if pass_over else next_in_order

	record.host.expecting_conditional = (pass_over and result is StmtConditional) if result else false
	return result if result else next_in_same_or_lower_depth


func _evaluate_self(host: PennyHost) -> Variant: return null

func _should_pass_over(record: Record) -> bool:
	return not (record.host.expecting_conditional and record.data[&"result"])
