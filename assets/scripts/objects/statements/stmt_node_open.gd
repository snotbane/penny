
## No description
class_name StmtOpen extends StmtNode

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'open'


# func _get_verbosity() -> Verbosity:
# 	return super._get_verbosity()


func _validate_self() -> PennyException:
	return null


# func _validate_self_post_setup() -> void:
# 	super._validate_self_post_setup()


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


func _execute(host: PennyHost) :
	await self.open_subject(host)
	return self.create_record(host)


func _undo(record: Record) -> void:
	self.subject_node.queue_free()


func _redo(record: Record) -> void:
	self.open_subject(record.host, false)


# func _next(record: Record) -> Stmt:
# 	return super._next(record)
