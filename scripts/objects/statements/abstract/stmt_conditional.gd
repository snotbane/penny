
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

func _get_verbosity() -> int:
	return 2

func _execute(host: PennyHost) -> Record:
	match type:
		ELSE:
			# host.handling_conditional = null
			return Record.new(host, self)
		_:
			var result = Record.new(host, self, host.evaluate_expression(tokens))
			# if result.attachment:
			# 	host.last_conditional = null
			# else:
			# 	host.last_conditional = result
			return result

## Because we can potentially jump into the middle of a conditional block, we need to be able to handle an elif/else statement (by skipping it) even if no 'if' statement was encountered. The shorthand to remember is that, an entire if/else chain is evaluated all at once, and always starts with 'if'. So if elif/else is encountered on its own, we should skip it.

## Furthermore, "skipping" a conditional statement for any reason should not even create a record. _execute must be capable of handling null records. The only time a conditional statement is recorded is if it starts with an `if` statement. Then every conditional that is CHECKED is recorded, until one returns true.

func _next(record: Record) -> Stmt:
	match type:
		IF:
			if record.attachment:
				record.host.handling_conditional = false
				return next_in_order
			record.host.handling_conditional = true
		ELIF:
			if record.host.handling_conditional:
				if record.attachment:
					record.host.handling_conditional = false
					return next_in_order
				record.host.handling_conditional = true
		ELSE:
			if record.host.handling_conditional:
				record.host.handling_conditional = false
				return next_in_order
			record.host.handling_conditional = false
	return next_in_depth

func _message(record: Record) -> Message:
	if record.attachment:
		return Message.new("%s (TRUE)" % reconstructed_string)
	else:
		return Message.new("[s]%s (FALSE)[/s]" % reconstructed_string)

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
