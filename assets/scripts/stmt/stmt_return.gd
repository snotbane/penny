
## No description
class_name StmtReturn extends Stmt

# func _init() -> void:
# 	pass


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


# func _populate(tokens: Array) -> void:
# 	pass


# func _reload() -> void:
# 	pass


func _execute(host: PennyHost) :
	return super._execute(host)


# func _undo(record: Record) -> void:
# 	pass


func _next(record: Record) -> Stmt:
	return null
