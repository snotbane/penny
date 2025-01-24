
class_name StmtAwait extends Stmt

var is_simple_timer_delay : bool
var await_value : Variant


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _get_is_rollable() -> bool:
	return not is_simple_timer_delay


func _get_is_skippable() -> bool:
	return not is_simple_timer_delay


func _populate(tokens: Array) -> void:
	is_simple_timer_delay = tokens[0].value is float or tokens[0].value is int
	if is_simple_timer_delay:
		await_value = float(tokens[0].value)
	else:
		await_value = Cell.Ref.new_from_tokens(tokens)


func _execute(host: PennyHost) :
	if is_simple_timer_delay:
		await host.get_tree().create_timer(await_value, false, false, false).timeout
	else:
		var object : Cell = (await_value as Cell.Ref).evaluate()
		var node : PennyNode = object.local_instance
		if node == null:
			printerr("Attempted to await the node of %s, but the node is null." % object)
		elif node is not PennyNode:
			printerr("Attempted to await the node of %s, but the node isn't a PennyNode." % object)
		else:
			await node.advanced
	return super._execute(host)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt:
# 	return super._next(record)
