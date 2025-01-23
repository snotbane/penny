
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


# func _create_history_listing(record: Record) -> HistoryListing:
# 	var result := super._create_history_listing(record)
# 	match record.data:
# 		true:
# 			result.message_label.text = "%s [code][color=#%s]PASSED[/color][/code]" % [_get_record_message(record), Penny.HAPPY_COLOR.to_html()]
# 		false:
# 			result.message_label.text = "%s [code][color=#%s]FAILED[/color][/code]" % [_get_record_message(record), Penny.ANGRY_COLOR.to_html()]
# 		_:
# 			result.message_label.text = "[s]%s [code]SKIPPED[/code]" % _get_record_message(record)
# 	return result


func _evaluate_self(host: PennyHost) -> Variant: return null


func _should_passover(record: Record) -> bool: return true
