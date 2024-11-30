
## No description
class_name StmtWait extends Stmt

var delay_seconds : float

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'wait'


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _validate_self() -> PennyException:
	if tokens.size() > 1 or tokens[0].type != Token.VALUE_NUMBER:
		return create_exception("Wait statement should have exactly one float parameter.")
	return null


func _validate_self_post_setup() -> void:
	delay_seconds = tokens[0].value


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


func _execute(host: PennyHost) :
	await host.get_tree().create_timer(delay_seconds, false, false, false).timeout
	return super._execute(host)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt:
# 	return super._next(record)
