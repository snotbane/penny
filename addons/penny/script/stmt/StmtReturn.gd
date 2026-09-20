## Performs a shallow exit; if there are calls remaining in the call stack, it will defer to it.
@tool
class_name StmtReturn
extends StmtExpress

func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _compile(script: PennyScript) -> void:
	pass


func _next(player: PennyPlayer, record: Penny.Record) -> Stmt:
	return null
