
class_name StmtNode extends Stmt

static var DEFAULT_CELL_REF := Cell.Ref.to(Cell.OBJECT)

## When initialized, this should always be global -- never relative.
var subject_ref : Cell.Ref

var subject : Cell :
	get: return subject_ref.evaluate()

var subject_node : Node :
	get: return subject.instance


func _get_verbosity() -> Verbosity:
	return Verbosity.NODE_ACTIVITY


func _populate(tokens: Array) -> void:
	subject_ref = Cell.Ref.new(str(tokens)) if tokens else DEFAULT_CELL_REF


func instantiate_subject(host: PennyHost) -> Node:
	return subject.instantiate(host)


func open_subject(host: PennyHost, wait : bool = true) :
	var node : Node = subject_node if subject_node else self.instantiate_subject(host)
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
