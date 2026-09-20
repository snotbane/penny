## Immediately ends execution, but preserves the call stack for later.
@tool
class_name StmtSuspend
extends StmtExpress

func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY
