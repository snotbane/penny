
class_name StmtConditional extends Stmt

enum {
	IF,
	ELIF,
	ELSE
}

var type : int

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token], _type: int) -> void:
	super._init(_address, _line, _depth, _tokens)
	type = _type

func _get_keyword() -> StringName:
	match type:
		0: return 'if'
		1: return 'elif'
		2: return 'else'
		_: return super._get_keyword()

func _show_record(record: Record) -> bool:
	return record.attachment != null

func _get_verbosity() -> int:
	return 2

func _execute(host: PennyHost) -> Record:
	var result = null
	match type:
		IF:			## always TRUE or FALSE
			result = host.evaluate_expression_as_boolean(tokens)
		ELIF:		## TRUE, FALSE, or NULL
			if host.expecting_conditional:
				result = host.evaluate_expression_as_boolean(tokens)
		ELSE:		## always TRUE or NULL
			if host.expecting_conditional:
				result = true
	return Record.new(host, self, result)

func _next(record: Record) -> Stmt:
	if record.attachment == null:
		record.host.expecting_conditional = false
		return next_in_depth

	var skip := true
	match type:
		IF:
			if record.attachment:
				skip = false
		ELIF:
			if record.host.expecting_conditional and record.attachment:
				skip = false
		ELSE:
			if record.host.expecting_conditional:
				skip = false

	var result : Stmt
	if skip: 	result = next_in_chain
	else:		result = next_in_order

	if result:
		record.host.expecting_conditional = skip and result is StmtConditional
		return result
	else:
		record.host.expecting_conditional = false
		return next_in_depth

func _message(record: Record) -> Message:
	match record.attachment:
		true:
			return Message.new("%s\t\t\t[code][color=LAWN_GREEN]PASSED[/color][/code]" % reconstructed_string)
		false:
			return Message.new("%s\t\t\t[code][color=DEEP_PINK]FAILED[/color][/code]" % reconstructed_string)
		_:
			return Message.new("[s]%s\t\t\t[code]SKIPPED[/code]" % reconstructed_string)

func _validate() -> PennyException:
	match type:
		IF:
			return validate_as_expression()
		ELIF:
			if not prev_in_depth is StmtConditional:
				return create_exception("Expected if or elif before elif statement")
			return validate_as_expression()
		ELSE:
			if not prev_in_depth is StmtConditional:
				return create_exception("Expected if or elif before else statement")
			return validate_as_no_tokens()
	return create_exception()
