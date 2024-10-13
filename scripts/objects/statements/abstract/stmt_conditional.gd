
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
	var result = host.evaluate_expression(tokens)
	match type:
		IF:			## always TRUE or FALSE
			pass
		ELIF:		## TRUE, FALSE, or NULL
			if not host.handling_conditional:
				result = null
		ELSE:		## always TRUE or NULL
			if host.handling_conditional:
				result = true
			else:
				result = null
	return Record.new(host, self, result)

func _next(record: Record) -> Stmt:
	var skip := true
	match type:
		IF:
			if record.attachment:
				skip = false
			record.host.handling_conditional = skip
		ELIF:
			if record.host.handling_conditional:
				if record.attachment:
					skip = false
				record.host.handling_conditional = skip
		ELSE:
			if record.host.handling_conditional:
				skip = false
			record.host.handling_conditional = false

	if skip: 	return next_in_depth
	else:		return next_in_order

func _message(record: Record) -> Message:
	match record.attachment:
		true:
			return Message.new("[code][color=LAWN_GREEN]PASSED\t\t[/color][/code] %s" % reconstructed_string)
		false:
			return Message.new("[code][color=DEEP_PINK]FAILED\t\t[/color][/code] %s" % reconstructed_string)
		_:
			return Message.new("[s][code]SKIPPED\t[/code] %s" % reconstructed_string)

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
