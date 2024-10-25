
## No description
class_name StmtClose extends StmtNode_

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)

func _get_is_halting() -> bool:
	return false

func _get_keyword() -> StringName:
	return 'close'

func _get_verbosity() -> Verbosity:
	return Verbosity.NODE_ACTIVITY

# func _is_record_shown_in_history(record: Record) -> bool:
# 	return true

# func _load() -> PennyException:
# 	return null

func _execute(host: PennyHost) -> Record:
	var node := self.get_existing_node(host)
	if node:
		if node is PennyNode:
			node.close()
		else:
			node.queue_free()
	else:
		self.push_exception("Attempted to close object at path '%s' but no node instance exists." % subject_path)
	return super._execute(host)

# func _next(record: Record) -> Stmt_:
# 	return next_in_order

# func _undo(record: Record) -> void:
# 	pass

func _message(record: Record) -> Message:
	return super._message(record)

func _validate() -> PennyException:
	return null

# func _setup() -> void:
# 	pass
