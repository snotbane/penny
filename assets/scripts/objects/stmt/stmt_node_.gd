
class_name StmtNode extends StmtCell


func _get_verbosity() -> Verbosity:
	return Verbosity.NODE_ACTIVITY


func spawn_subject(host: PennyHost) -> Node:
	return subject.spawn(host)


func open_subject(host: PennyHost, wait : bool = true) :
	var node : Node = subject_node if subject_node else self.spawn_subject(host)
	if node is Actor:
		await node.open(wait)
	return node


func close_subject(host : PennyHost, wait : bool = true) :
	var node := self.subject_node
	if node == null: return

	if node is Actor:
		await node.close(wait)
	else:
		node.queue_free()

# func _cleanup(record: Record) -> void:
# 	pass

# func _undo(record: Record) -> void:
# 	super._undo(record)

# func _redo(record: Record) -> void:
# 	super._redo(record)
