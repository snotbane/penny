
## No description
class_name StmtReturn extends Stmt


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _execute(host: PennyHost) :
	return super._execute(host)


func _next(record: Record) -> Stmt:
	return null
