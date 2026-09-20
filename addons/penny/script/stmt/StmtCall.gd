@tool
class_name StmtCall
extends StmtJump

func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	super._draw(player, record)

	player.ledger.push_call(get_stmt_in_order())
