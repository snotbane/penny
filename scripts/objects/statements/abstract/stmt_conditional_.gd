
class_name StmtConditional_ extends Stmt_

var expr : Expr

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)


func _get_keyword() -> StringName:
	return 'check'


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _validate_self() -> PennyException:
	return create_exception()


func _validate_self_post_setup() -> void:
	expr = Expr.from_tokens(self, tokens)


# func _validate_cross() -> PennyException:
# 	return null


func _execute(host: PennyHost) -> Record:
	return create_record(host, false, _evaluate_self(host))


# func _undo(record: Record) -> void:
# 	pass


func _next(record: Record) -> Stmt_:
	if record.attachment == null:
		record.host.expecting_conditional = false
		return next_in_same_or_lower_depth

	var skip := _should_skip(record)

	var result : Stmt_
	if skip: 	result = next_in_same_depth
	else:		result = next_in_order

	if result:
		record.host.expecting_conditional = skip and result is StmtConditional_
		return result
	else:
		record.host.expecting_conditional = false
		return next_in_same_or_lower_depth


func _message(record: Record) -> Message:
	match record.attachment:
		true:
			return Message.new("%s [code][color=#%s]PASSED[/color][/code]" % [reconstructed_string, Penny.HAPPY_COLOR.to_html()])
		false:
			return Message.new("%s [code][color=#%s]FAILED[/color][/code]" % [reconstructed_string, Penny.ANGRY_COLOR.to_html()])
		_:
			return Message.new("[s]%s [code]SKIPPED[/code]" % reconstructed_string)


func _evaluate_self(host: PennyHost) -> Variant: return null


func _should_skip(record: Record) -> bool: return true
