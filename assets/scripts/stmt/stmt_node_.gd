
class_name StmtNode extends StmtCell


func _get_verbosity() -> Verbosity:
	return Verbosity.NODE_ACTIVITY


func instantiate_subject(host: PennyHost) -> Node:
	return subject.instantiate(host)


func open_subject(host: PennyHost, wait : bool = true) :
	var node : Node = subject_node if subject_node else self.instantiate_subject(host)
	if node is CellNode:
		await node.open(wait)
	return node


func close_subject(host : PennyHost, wait : bool = true) :
	var node := self.subject_node
	if node == null: return

	if node is CellNode:
		await node.close(wait)
	else:
		node.queue_free()
