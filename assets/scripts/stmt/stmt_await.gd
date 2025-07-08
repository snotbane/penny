
class_name StmtAwait extends Stmt

var is_simple_timer_delay : bool
var expr : Variant


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _get_is_rollable() -> bool:
	return not is_simple_timer_delay


func _get_is_skippable() -> bool:
	return not is_simple_timer_delay


func _populate(tokens: Array) -> void:
	is_simple_timer_delay = tokens[0].value is float or tokens[0].value is int
	if is_simple_timer_delay:
		expr = float(tokens[0].value)
	else:
		expr = Path.new_from_tokens(tokens)


func _execute(record: Record) :
	if is_simple_timer_delay:
		await record.host.get_tree().create_timer(expr, false, false, false).timeout
	else:
		var object : Cell = expr.evaluate()
		if object != null:
			var node : Actor = object.instance
			if node is Actor:
				await node.advanced
			else:
				printerr("Attempted to await the node of %s, but the node isn't an Actor." % object)
		else:
			printerr("Attempted to await the node of %s, but the object is null." % object)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt:
# 	return super._next(record)


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]await : %s[/color][/code]" % Penny.get_value_as_bbcode_string(expr)
