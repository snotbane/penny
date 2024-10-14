
class_name StmtPrint extends Stmt

func _get_keyword() -> StringName:
	return "print"

func _get_verbosity() -> Verbosity:
	return Verbosity.DEBUG_MESSAGES

func _execute(host: PennyHost) -> Record:
	print(tokens[0])
	return super._execute(host)

# func _undo(record: Record) -> void:
# 	pass

func _message(record: Record) -> Message:
	return Message.new(tokens[0].value)

func _validate() -> PennyException:
	return validate_as_expression()
