@tool
class_name StmtIf
extends StmtBranch

@export_storage
var address_skip: Address


func _compile(script: PennyScript) -> void:
	address_skip = Address.new(get_stmt_idx_in_depth_less_than_or_equal(+1))


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	super._draw(player, record)

	record.data = {
		&"result": record.data,
		&"satisfied": record.data as bool,
	}

	record.next = (
		get_stmt_next_in_order()
		if record.data.satisfied
		else address_skip.stmt
	)
