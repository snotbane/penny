
class_name StmtConditional_ extends StmtExpr_

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'check'


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


# func _validate_self() -> PennyException:
# 	return create_exception()


# func _validate_self_post_setup() -> void:
# 	super._validate_self_post_setup()


# func _validate_cross() -> PennyException:
# 	return null


func _execute(host: PennyHost) -> Record:
	return create_record(host, false, _evaluate_self(host))


# func _undo(record: Record) -> void:
# 	pass


func _next(record: Record) -> Stmt:
	if record.attachment == null:
		record.host.expecting_conditional = false
		return next_in_same_or_lower_depth

	var skip := _should_skip(record)

	var result : Stmt
	if skip: 	result = next_in_same_depth
	else:		result = next_in_order

	if result:
		record.host.expecting_conditional = skip and result is StmtConditional_
		return result
	else:
		record.host.expecting_conditional = false
		return next_in_same_or_lower_depth


func _create_history_listing(record: Record) -> HistoryListing:
	var result := super._create_history_listing(record)
	match record.attachment:
		true:
			result.label.text = "%s [code][color=#%s]PASSED[/color][/code]" % [reconstructed_string, Penny.HAPPY_COLOR.to_html()]
		false:
			result.label.text = "%s [code][color=#%s]FAILED[/color][/code]" % [reconstructed_string, Penny.ANGRY_COLOR.to_html()]
		_:
			result.label.text = "[s]%s [code]SKIPPED[/code]" % reconstructed_string
	return result


func _evaluate_self(host: PennyHost) -> Variant: return null


func _should_skip(record: Record) -> bool: return true
