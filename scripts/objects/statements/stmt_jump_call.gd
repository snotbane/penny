
## No description
class_name StmtJumpCall extends StmtJump

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)

# func _get_is_halting() -> bool:
# 	return false

func _get_keyword() -> StringName:
	return 'call'

# func _get_verbosity() -> Verbosity:
# 	return super._get_verbosity()

# func _is_record_shown_in_history(record: Record) -> bool:
# 	return true

# func _load() -> PennyException:
# 	return null

func _execute(host: PennyHost) -> Record:
	host.call_stack.push_back(next_in_order.address)
	return super._execute(host)

# func _next(record: Record) -> Stmt_:
# 	return next_in_order

# func _undo(record: Record) -> void:
# 	pass

func _message(record: Record) -> Message:
	return super._message(record)

func _validate() -> PennyException:
	return super._validate()
