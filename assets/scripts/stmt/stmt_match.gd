
class_name StmtMatch extends StmtExpr


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _execute(host: PennyHost) :
	host.expecting_conditional = true
	return super._execute(host)
