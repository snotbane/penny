
## Statement that calls a function (and undoes it, if available).
## A called function's parameters must start with a [PennyHost].
## An undo function is not required, but if it exists, it must start with a [Record] parameter.
class_name StmtFunc extends StmtCell

const UNDO_SUFFIX := &"_undo"

var execute_callable : Callable :
	get: return subject
var undo_callable : Callable :
	get: return Callable(execute_callable.get_object(), execute_callable.get_method() + UNDO_SUFFIX)

var arguments : Array

func _populate(tokens: Array) -> void:
	var group_index : int = -1
	for i in tokens.size():
		if tokens[i].type != PennyScript.Token.Type.OPERATOR or tokens[i].value.type != Expr.Op.GROUP_OPEN: continue
		group_index = i
		break
	if group_index == -1: printerr("Function start not found."); return

	var left := tokens.slice(0, group_index)
	print(left)

	var right := tokens.slice(group_index + 1, -1)
	arguments = new_args_from_tokens(right)

	super._populate(left)


func _execute(host: PennyHost) :
	var evaluated_arguments : Array = [host]
	for arg in arguments:
		evaluated_arguments.push_back(arg.evaluate() if arg is Expr else arg)

	await execute_callable.callv(evaluated_arguments)

	return create_record(host, { &"args": evaluated_arguments })


func _undo(record: Record) -> void :
	var evaluated_arguments : Array = [record]
	evaluated_arguments.append_array(record.data[&"args"])
	undo_callable.callv(evaluated_arguments)


## Separates tokens by iterator.
static func new_args_from_tokens(tokens: Array, _stmt: Stmt = null) -> Array:
	if tokens.size() == 0: return []

	var result : Array = []
	var start := 0
	for i in tokens.size():
		if tokens[i].type != PennyScript.Token.Type.OPERATOR or tokens[i].value.type != Expr.Op.ITERATOR: continue
		result.push_back(Expr.new_from_tokens(tokens.slice(start, i)))
		start = i + 1
	result.push_back(Expr.new_from_tokens(tokens.slice(start, tokens.size())))
	return result


