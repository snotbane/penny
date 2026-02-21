## Exhausts execution. If there are more [Stmt]s in the call stack, this will move execution there.
class_name StmtReturn extends Stmt

func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY

func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]return[/code]"


func _next(record: Record) -> Stmt:
	return null
