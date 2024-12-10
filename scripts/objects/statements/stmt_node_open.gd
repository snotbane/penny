
## No description
class_name StmtOpen extends StmtNode

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return "open"


# func _get_verbosity() -> Verbosity:
# 	return super._get_verbosity()


func _validate_self() -> PennyException:
	return null


# func _validate_self_post_setup() -> void:
# 	super._validate_self_post_setup()


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


func _execute(host: PennyHost) :
	var node : Node = self.instantiate_node_from_path(host, subject_path)
	if node is PennyNode:
		await node.open(true)
	return self.create_record(host)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt:
# 	return super._next(record)
