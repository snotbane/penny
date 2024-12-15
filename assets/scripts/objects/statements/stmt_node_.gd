
## Statement that interacts with a PennyObject and its Node instance via the supplied Path.
class_name StmtNode extends Stmt

## Path to the object.
var subject_path : Path

var subject : PennyObject :
	get: return self.subject_path.evaluate()

var subject_node : Node :
	get:
		return subject.local_instance


# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'node'


func _get_verbosity() -> Verbosity:
	return Verbosity.NODE_ACTIVITY


# func _validate_self() -> PennyException:
# 	return super._validate_self()


func _validate_self_post_setup() -> void:
	if tokens:
		subject_path = Path.from_tokens(tokens)
	else:
		subject_path = _get_default_subject()


# func _validate_cross() -> PennyException:
# 	return null


# func _execute(host: PennyHost) :
# 	return super._execute(host)


# func _undo(record: Record) -> void:
# 	if record.attachment:
# 		record.attachment.queue_free()


# func _next(record: Record) -> Stmt:
# 	return next_in_order


func _get_default_subject() -> Path:
	return Path.from_single(PennyObject.BILTIN_OBJECT_NAME)


func instantiate_node_from_object(host: PennyHost, obj : PennyObject) -> Node:
	return obj.instantiate(host)


func instantiate_node_from_path(host: PennyHost, path := subject_path) -> Node:
	return instantiate_node_from_object(host, path.evaluate())


func open_subject(host: PennyHost, wait : bool = true) :
	var node : Node = self.instantiate_node_from_path(host, subject_path)
	if node is PennyNode:
		await node.open(wait)
	return node


func close_subject(host : PennyHost, wait : bool = true) :
	var node := self.subject_node
	if node == null: return

	if node is PennyNode:
		await node.close(wait)
	else:
		node.queue_free()
