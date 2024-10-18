
## No description
class_name StmtJump extends Stmt_

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)

# func _get_is_halting() -> bool:
# 	return false

func _get_keyword() -> StringName:
	return 'jump'

func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY

# func _is_record_shown_in_history(record: Record) -> bool:
# 	return true

# func _load() -> PennyException:
# 	return null

func _execute(host: PennyHost) -> Record:
	var label = host.evaluate_expression_or_identifier(tokens)
	return Record.new(host, self, label)

func _next(record: Record) -> Stmt_:
	return Penny.get_stmt_from_label(record.attachment)

# func _undo(record: Record) -> void:
# 	pass

# func _message(record: Record) -> Message:
# 	return super._message(record)

func _validate() -> PennyException:
	return validate_as_expression()
