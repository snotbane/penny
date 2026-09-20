## Ends with the : operator and routes execution based on conditions of this or following [Stmt]s.
@abstract
@tool
class_name StmtBranch
extends StmtExpress

func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _populate(tokens: Array) -> void:
	if tokens.back().type == PennyScript.Token.Type.OPERATOR and tokens.back().type == PennyScript.Token.Operator.ACCESS:
		tokens.pop_back()

	super._populate(tokens)


func _next(player: PennyPlayer, record: Penny.Record) -> Stmt:
	return record.next
