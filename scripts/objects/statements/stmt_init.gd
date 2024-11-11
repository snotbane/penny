
## No description
class_name StmtInit extends Stmt

var order := 0

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'init'


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _validate_self() -> PennyException:
	if tokens.is_empty(): return null
	if tokens.size() > 1 or tokens[0].type != Token.VALUE_NUMBER:
		return create_exception("Init statement should only have one int parameter or none.")
	return null


func _validate_self_post_setup() -> void:
	if tokens.size() >= 1:
		order = int(tokens[0].value)


func _validate_cross() -> PennyException:
	Penny.inits.push_back(self)
	return null


func _execute(host: PennyHost) -> Record:
	return super._execute(host)

# func _next(record: Record) -> Stmt:
# 	return next_in_order

# func _undo(record: Record) -> void:
# 	pass
