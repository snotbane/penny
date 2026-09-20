@tool
class_name StmtMatch
extends StmtBranch


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	super._draw(player, record)

	record.data = {
		&"result": record.data,
		&"satisfied": false,
	}


func _next(player: PennyPlayer, record: Penny.Record) -> Stmt:
	return get_stmt_next_in_order()
