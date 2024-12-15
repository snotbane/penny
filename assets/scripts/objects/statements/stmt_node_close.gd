
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
	await self.close_subject(host)
	return super._execute(host)


func _undo(record: Record) -> void:
	self.open_subject(record.host, false)


func _redo(record: Record) -> void:
	self.subject_node.queue_free()


# func _next(record: Record) -> Stmt:
# 	return next_in_order
