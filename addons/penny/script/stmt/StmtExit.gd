## Immediately ends execution, and clears the call stack.
@tool
class_name StmtExit
extends StmtReturn

func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	super._draw(player, record)

	player.ledger.clear_call_stack()
