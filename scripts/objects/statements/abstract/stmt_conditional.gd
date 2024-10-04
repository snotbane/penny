
class_name StmtConditional extends Stmt

enum {
	IF,
	ELIF,
	ELSE
}

var type : int

func _init(_line: int, _depth: int, _tokens: Array[Token], _type: int) -> void:
	super._init(_line, _depth, _tokens)
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
	return Record.new(host, self, host.evaluate_expression(tokens))

func _next(record: Record) -> Address:
	if record.attachment:
		return super._next(record)
	else:
		return address.copy(2)

func _message(record: Record) -> Message:
	if record.attachment:
		return Message.new("%s (TRUE)" % reconstructed_string)
	else:
		return Message.new("[s]%s (FALSE)[/s]" % reconstructed_string)


func _validate() -> PennyException:
	match type:
		2:
			return validate_as_no_tokens()
		_:
			return validate_as_expression()
