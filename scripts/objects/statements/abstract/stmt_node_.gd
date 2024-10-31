
## Statement that interacts with a PennyObject and its Node instance via the supplied Path.
class_name StmtNode_ extends Stmt_

var subject_path : Path


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
		subject_path = Path.new([PennyObject.BILTIN_OBJECT_NAME])


# func _validate_cross() -> PennyException:
# 	return null


# func _execute(host: PennyHost) -> Record:
# 	return super._execute(host)


# func _undo(record: Record) -> void:
# 	if record.attachment:
# 		record.attachment.queue_free()


# func _next(record: Record) -> Stmt_:
# 	return next_in_order


func _message(record: Record) -> Message:
	return super._message(record)


func instantiate_node(host: PennyHost, path := subject_path) -> Node:
	var obj : PennyObject = path.evaluate(host.data_root)
	if obj:
		var node = obj.instantiate_from_lookup(host)
		return node
	return null


func get_existing_node(host: PennyHost, path := subject_path) -> Node:
	var obj : PennyObject = path.evaluate(host.data_root)
	if obj:
		var node : Node = obj.local_instance
		return node
	return null
