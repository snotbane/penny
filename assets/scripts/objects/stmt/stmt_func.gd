
## Statement that calls a function (and undoes it, if available).
## A called function must always start with a [Funx] parameter and must also be awaitable. It can return anything.
## Undo, redo, and cleanup functions are not required, but if any exists, they must start with a [Record] parameter.
class_name StmtFunc extends StmtCell

const CLEANUP_SUFFIX := &"__cleanup"
const UNDO_SUFFIX := &"__undo"
const REDO_SUFFIX := &"__redo"

var is_awaited : bool
var arguments : Array
var execute_function_ref : Path


var execute_function : Callable :
	get: return execute_function_ref.evaluate()

var cleanup_function_name : StringName :
	get: return execute_function.get_method() + CLEANUP_SUFFIX
var cleanup_function : Callable :
	get: return Callable(execute_function.get_object(), cleanup_function_name)

var undo_function_name : StringName :
	get: return execute_function.get_method() + UNDO_SUFFIX
var undo_function : Callable :
	get: return Callable(execute_function.get_object(), undo_function_name)

var redo_function_name : StringName :
	get: return execute_function.get_method() + REDO_SUFFIX
var redo_function : Callable :
	get: return Callable(execute_function.get_object(), redo_function_name)

var is_reserved_function : bool :
	get: return local_subject_ref.ids.size() == 1


# func _get_is_skippable() -> bool:
# 	return false


func _init(__is_awaited__: bool = false) -> void:
	super._init(StorageQualifier.NONE)
	is_awaited = __is_awaited__

func _populate(tokens: Array) -> void:
	var group_index : int = -1
	for i in tokens.size():
		if tokens[i].type != PennyScript.Token.Type.OPERATOR or tokens[i].value.type != Op.GROUP_OPEN: continue
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
	var funx := Funx.new(record.host, is_awaited)
	funx.record = record
	var evaluated_arguments : Array = [funx]
	for arg in arguments: evaluated_arguments.push_back(arg.evaluate() if arg is Expr else arg)

	record.data.merge({
		&"args": evaluated_arguments
	})


func _execute(record: Record) :
	record.data[&"result"] = await execute_function.callv(record.data[&"args"])

func _cleanup(record: Record, execution_response: ExecutionResponse) :
	super._cleanup(record, execution_response)
	if cleanup_function.is_valid():
		await cleanup_function.call(record, execution_response)

func _undo(record: Record) -> void:
	super._undo(record)
	if undo_function.is_valid():
		undo_function.call(record)

func _redo(record: Record) -> void:
	super._redo(record)
	if redo_function.is_valid():
		redo_function.call(record)


func _serialize_record(record: Record) -> Variant:
	var args = record.data[&"args"].duplicate()
	args.pop_front()
	return record.data.merged({
		&"args": args,
	}, true)

func _deserialize_record(record: Record, json: Variant) -> Variant:
	var args = json[&"args"]
	args.push_back(Funx.new(record.host, is_awaited))
	return json.merged({
		&"args": args,
	}, true)


## Separates tokens by iterator.
static func new_args_from_tokens(tokens: Array, _stmt: Stmt = null) -> Array:
	if tokens.size() == 0: return []

	var result : Array = []
	var start := 0
	for i in tokens.size():
		if tokens[i].type != PennyScript.Token.Type.OPERATOR or tokens[i].value.type != Op.ITERATOR: continue
		result.push_back(Expr.new_from_tokens(tokens.slice(start, i)))
		start = i + 1
	result.push_back(Expr.new_from_tokens(tokens.slice(start, tokens.size())))
	return result
