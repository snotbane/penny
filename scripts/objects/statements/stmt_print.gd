
class_name StmtPrint extends Stmt_

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)


func _get_keyword() -> StringName:
	return "print"


func _get_verbosity() -> Verbosity:
	return Verbosity.DEBUG_MESSAGES


func _validate_self() -> PennyException:
	return validate_as_expression()


# func _validate_self_post_setup() -> void:
# 	pass


# func _validate_cross() -> PennyException:
# 	return null


func _execute(host: PennyHost) -> Record:
	var expr := Expr.from_tokens(self, tokens)
	var value = expr.evaluate(self.get_owning_object(host.data_root))
	var s := str(value)
	print(s)
	return create_record(host, false, s)


# func _undo(record: Record) -> void:
# 	pass


# func _next(record: Record) -> Stmt_:
# 	return next_in_order


func _message(record: Record) -> Message:
	return Message.new(record.attachment)
