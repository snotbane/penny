
## No description
class_name StmtClose extends StmtNode

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'close'


func _get_verbosity() -> Verbosity:
	return Verbosity.NODE_ACTIVITY


func _validate_self() -> PennyException:
	return null


# func _validate_self_post_setup() -> void:
# 	pass


# func _validate_cross() -> PennyException:
# 	return null


func _execute(host: PennyHost) :
	var node := self.subject_node
	if node:
		if node is PennyNode:
			await node.close(true)
		else:
			node.queue_free()
	else:
		self.push_exception("Attempted to close object at path '%s' but no node instance exists." % subject_path)
	return super._execute(host)


func _undo(record: Record) -> void:
	var node : Node = self.instantiate_node_from_path(record.host, subject_path)
	if node is PennyNode:
		node.open()


func _redo(record: Record) -> void:
	self.subject_node.queue_free()


# func _next(record: Record) -> Stmt:
# 	return next_in_order
