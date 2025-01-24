
class_name StmtJumpCall extends StmtJump


func _execute(host: PennyHost) :
	host.call_stack.push_back(next_in_order)
	return super._execute(host)


func _undo(record: Record) -> void:
	record.host.call_stack.pop_back()


func _redo(record: Record) -> void:
	record.host.call_stack.push_back(next_in_order)
