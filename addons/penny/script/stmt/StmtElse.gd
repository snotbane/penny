@tool
class_name StmtElse
extends StmtBranch

@export_storage
var ADDRESS_HEAD: Address

@export_storage
var ADDRESS_END: Address


func get_head_record(player: PennyPlayer) -> Penny.Record:
	return player.ledger.find_recent_record_from_stmt(ADDRESS_HEAD.stmt)


func _compile(script: PennyScript) -> void:
	ADDRESS_HEAD = Address.new(get_stmt_idx_in_depth_less_than(-1))
	ADDRESS_END = Address.new(get_stmt_idx_in_depth_less_than(+1))


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	super._draw(player, record)
	assert(record.data == null)

	var head_record := get_head_record(player)
	record.next = (
		ADDRESS_END.stmt
		if head_record.data.satisfied
		else null
	)

	head_record.data.satisfied = true

func _next(player: PennyPlayer, record: Penny.Record) -> Stmt:
	return record.next if record.next else get_stmt_in_order()
