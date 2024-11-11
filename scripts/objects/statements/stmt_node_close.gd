
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


# func _undo(record: Record) -> void:
# 	pass


# func _next(record: Record) -> Stmt:
# 	return next_in_order
