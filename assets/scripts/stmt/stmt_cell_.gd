
## Generic statement for referring to a [Cell].
class_name StmtCell extends Stmt

static var DEFAULT_CELL_REF := Cell.Ref.to(Cell.OBJECT)

## When initialized, this should always be global -- never relative.
var subject_ref : Cell.Ref

var subject : Variant :
	get: return subject_ref.evaluate()

var subject_node : Node :
	get: return subject.instance if subject is Cell else null


func _populate(tokens: Array) -> void:
	subject_ref = Cell.Ref.new_from_tokens(tokens)

	if subject_ref == null:
		printerr("subject_ref evaluated to null from tokens: %s" % str(tokens))
		owner.errors.push_back("subject_ref evaluated to null from tokens: %s" % str(tokens))
