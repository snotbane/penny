
## Statement that calls a function (and undoes it, if available)
class_name StmtFunc extends StmtCell

const UNDO_SUFFIX := &"_undo"

var execute_name : StringName
var undo_name : StringName :
	get: return execute_name + UNDO_SUFFIX

var arguments : Array

func _populate(tokens: Array) -> void:
	var group_index : int = -1
	for i in tokens.size():
		if tokens[i].type != PennyScript.Token.Type.OPERATOR or tokens[i].value.type != Expr.Op.GROUP_OPEN: continue
		group_index = i
		break
	if group_index == -1: printerr("Function start not found."); return

	if tokens[group_index - 1].type != PennyScript.Token.Type.IDENTIFIER: printerr("Expected function identifier, found '%s' instead." % tokens[group_index - 1]); return
	execute_name = tokens[group_index - 1].value

	var left := tokens.slice(0, max(0, group_index - 2))

	var right := tokens.slice(group_index + 1, -1)
	arguments = new_args_from_tokens(right)

	print("Call: %s, Subject: %s Arguments %s" % [execute_name, subject_ref, arguments])

	super._populate(left)


func _execute(host: PennyHost) :
	var evaluated_arguments : Array
	for arg in arguments:
		evaluated_arguments.push_back(arg.evaluate() if arg is Expr else arg)

	await call_function(subject_node if subject_node else host, execute_name, evaluated_arguments)

	return create_record(host, { &"args": evaluated_arguments })


func _undo(record: Record) -> void :
	call_function(subject_node if subject_ref else record.host, undo_name, record.data[&"args"], false)


static func call_function(obj: Object, function: StringName, args: Array, warn := true) :
	if obj == null: printerr("Attempted to call function '%s' on a null object." % [function]); return
	if warn and not obj.has_method(function): printerr("Attempted to call function '%s' on object '%s', but no method exists." % [function, obj]); return

	obj.callv(function, args)


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


