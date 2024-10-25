
class_name StmtPrint extends Stmt_


func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)


func _get_keyword() -> StringName:
	return "print"


func _get_verbosity() -> Verbosity:
	return Verbosity.DEBUG_MESSAGES


func _execute(host: PennyHost) -> Record:
	var expr := Expr.from_tokens(self, tokens)
	var value = expr.evaluate_deep(get_nested_object(host.data_root))
	var s := str(value)
	print(s)
	return create_record(host, false, s)


# func _undo(record: Record) -> void:
# 	pass


func _message(record: Record) -> Message:
	return Message.new(record.attachment)


func _validate() -> PennyException:
	return validate_as_expression()
