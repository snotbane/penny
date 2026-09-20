@tool
class_name StmtElif
extends StmtBranch

@export_storage
var address_prev: Address

@export_storage
var address_skip: Address


func _compile(script: PennyScript) -> void:
	address_prev = Address.new(get_stmt_idx_in_depth_equal(-1))
	assert(
		get_stmt_in_owner(address_prev.idx) is StmtIf
		or get_stmt_in_owner(address_prev.idx) is StmtElif,
		"StmtElif must be preceeded by a StmtIf or StmtElif."
	)

	address_skip = Address.new(get_stmt_idx_in_depth_less_than_or_equal(+1))


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	super._draw(player, record)

	var prev_record := player.ledger.find_recent_record_from_stmt(address_prev.stmt)

	if prev_record.data.satisfied:
		record.data = {
			&"result": null,
			&"satisfied": true,
		}
		record.next = address_skip.stmt

	else:
		record.data = {
			&"result": record.data,
			&"satisfied": record.data as bool,
		}
		record.next = (
			get_stmt_next_in_order()
			if record.data.satisfied
			else address_skip.stmt
		)
