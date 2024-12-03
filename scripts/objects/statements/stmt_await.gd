
## No description
class_name StmtAwait extends Stmt

var is_simple_timer_delay : bool
var await_value : Variant

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'await'


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _validate_self() -> PennyException:
	if tokens.size() == 0:
		return create_exception("Await statement should have at least one parameter.")
	return null


func _validate_self_post_setup() -> void:
	is_simple_timer_delay = tokens[0].value is float or tokens[0].value is int
	if is_simple_timer_delay:
		await_value = float(tokens[0].value)
	else:
		await_value = Path.from_tokens(tokens)



# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


func _execute(host: PennyHost) :
	if is_simple_timer_delay:
		await host.get_tree().create_timer(await_value, false, false, false).timeout
	else:
		var object : PennyObject = (await_value as Path).evaluate()
		var node : PennyNode = object.local_instance
		if node == null:
			self.push_exception("Attempted to await the node of %s, but the node is null." % object)
		elif node is not PennyNode:
			self.push_warn("Attempted to await the node of %s, but the node isn't a PennyNode." % object)
		else:
			print("awaiting ", node)
			await node.advanced
	return super._execute(host)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt:
# 	return super._next(record)
