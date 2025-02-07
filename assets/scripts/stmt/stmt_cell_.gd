
## Generic statement for referring to a [Cell].
class_name StmtCell extends Stmt

static var DEFAULT_CELL_REF := Cell.Ref.to(Cell.OBJECT)

var _local_subject_ref : Cell.Ref
var local_subject_ref : Cell.Ref :
	get: return _local_subject_ref
	set(value):
		_local_subject_ref = value
		_subject_ref = context_ref.append(local_subject_ref) if _local_subject_ref.rel else _local_subject_ref


var _subject_ref : Cell.Ref
var subject_ref : Cell.Ref :
	get: return _subject_ref

var subject : Variant :
	get: return subject_ref.evaluate()

var subject_node : Node :
	get: return subject.instance if subject is Cell else null


func _populate(tokens: Array) -> void:
	local_subject_ref = Cell.Ref.new_from_tokens(tokens)

	if subject_ref == null:
		printerr("subject_ref evaluated to null from tokens: %s" % str(tokens))
		owner.errors.push_back("subject_ref evaluated to null from tokens: %s" % str(tokens))
