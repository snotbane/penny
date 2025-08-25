
## Statement that calls a function (and undoes it, if available).
## A called function's parameters must start with a [PennyHost] and be awaitable. It can return anything.
## An undo function is not required, but if it exists, it must start with a [Record] parameter.
class_name StmtFunc extends StmtCell

const UNDO_SUFFIX := &"_undo"

var is_awaited : bool
var arguments : Array
var execute_function_ref : Path


var execute_function : Callable :
	get: return execute_function_ref.evaluate()
var undo_function : Callable :
	get: return Callable(execute_function.get_object(), execute_function.get_method() + UNDO_SUFFIX)

var is_reserved_function : bool :
	get: return local_subject_ref.ids.size() == 1

func _populate(tokens: Array) -> void:
	self.is_awaited = tokens.front().type == PennyScript.Token.Type.KEYWORD and tokens.front().value == &"await"
	if self.is_awaited:	tokens.pop_front()

	var group_index : int = -1
	for i in tokens.size():
		if tokens[i].type != PennyScript.Token.Type.OPERATOR or tokens[i].value.type != Expr.Op.GROUP_OPEN: continue
		group_index = i
		break
	assert(group_index != -1, "Function start not found.")

	var left := tokens.slice(0, group_index)
	var execute_name : StringName = left.pop_back().value
	if left: left.pop_back()

	var right := tokens.slice(group_index + 1, -1)
	arguments = new_args_from_tokens(right)

	super._populate(left)

	execute_function_ref = local_subject_ref.duplicate()
	execute_function_ref.ids.push_back(execute_name)


func _prep(record: Record) -> void:
	var evaluated_arguments : Array = [Funx.new(record.host, is_awaited)]
	for arg in arguments: evaluated_arguments.push_back(arg.evaluate() if arg is Expr else arg)

	record.data.merge({
		&"args": evaluated_arguments
	})


func _execute(record: Record) :
	var result : Variant = await execute_function.callv(record.data[&"args"])

	record.data[&"result"] = result


func _undo(record: Record) -> void:
	super._undo(record)
	var evaluated_arguments : Array = [record]
	evaluated_arguments.append_array(record.data[&"args"])
	undo_function.callv(evaluated_arguments)


func _redo(record: Record) -> void:
	super._redo(record)


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
