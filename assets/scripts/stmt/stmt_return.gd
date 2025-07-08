
## No description
class_name StmtReturn extends Stmt


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


# func _execute(host: PennyHost) :
# 	return super._execute(host)


func _next(record: Record) -> Stmt:
	return null


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]return[/code]"
