
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
	expr = Expr.new_from_tokens(tokens)
	var eval = expr.evaluate()
	is_simple_timer_delay = eval is float or eval is int


func _pre_execute(record: Record) -> void:
	var wait : Variant = expr.evaluate(context)
	assert(wait != null, "Attempted to await %s, but the wait object is null. (Does the Cell's instance exist?)" % wait)
	is_simple_timer_delay = wait is float or wait is int
	record.data[&"wait"] = wait


func _execute(record: Record) :
	var wait : Variant = record.data[&"wait"]
	if is_simple_timer_delay:
		await record.host.get_tree().create_timer(wait, false, false, false).timeout
	elif wait is Signal:
		await wait
	else:
		printerr("Attempted to await %s, but we don't know what to do with it." % wait)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt:
# 	return super._next(record)


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]await : %s[/color][/code]" % Penny.get_value_as_bbcode_string(expr)
