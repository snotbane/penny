
class_name StmtConditional_ extends Stmt_

var expr : Expr

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)

func _get_keyword() -> StringName:
	return 'check'

func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY

func _is_record_shown_in_history(record: Record) -> bool:
	return record.attachment != null

func _execute(host: PennyHost) -> Record:
	return create_record(host, _evaluate_self(host))

func _next(record: Record) -> Stmt_:
	if record.attachment == null:
		record.host.expecting_conditional = false
		return next_in_depth

	var skip := _should_skip(record)

	var result : Stmt_
	if skip: 	result = next_in_chain
	else:		result = next_in_order

	if result:
		record.host.expecting_conditional = skip and result is StmtConditional_
		return result
	else:
		record.host.expecting_conditional = false
		return next_in_depth

func _message(record: Record) -> Message:
	match record.attachment:
		true:
			return Message.new("%s [code][color=#%s]PASSED[/color][/code]" % [reconstructed_string, Penny.HAPPY_COLOR.to_html()])
		false:
			return Message.new("%s [code][color=#%s]FAILED[/color][/code]" % [reconstructed_string, Penny.ANGRY_COLOR.to_html()])
		_:
			return Message.new("[s]%s [code]SKIPPED[/code]" % reconstructed_string)

func _validate() -> PennyException:
	return create_exception()

func _setup() -> void:
	expr = Expr.from_tokens(self, tokens)

func _evaluate_self(host: PennyHost) -> Variant: return null

func _should_skip(record: Record) -> bool: return true
