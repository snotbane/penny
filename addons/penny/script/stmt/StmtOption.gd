@tool
class_name StmtOption
extends StmtBranch

@export_storage
var ADDRESS_HEAD: Address

@export_storage
var ADDRESS_NEXT_OPTION: Address

@export_storage
var ADDRESS_END: Address


func get_match_head_record(player: PennyPlayer) -> Penny.Record:
	return player.ledger.find_recent_record_from_stmt(ADDRESS_HEAD.stmt)


func _compile(script: PennyScript) -> void:
	ADDRESS_HEAD = Address.new(get_stmt_idx_in_depth_less_than(-1))
	ADDRESS_NEXT_OPTION = Address.new(get_stmt_idx_in_depth_less_than_or_equal(+1))
	ADDRESS_END = Address.new(get_stmt_idx_in_depth_less_than(+1))


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	var head := get_match_head_record(player)
	if head.data.satisfied:
		record.data = null
		record.next = ADDRESS_END.stmt
		return

	super._draw(player, record)

	if Penny.Express.type_and_value_equals(head.data.result, record.data):
		head.data.satisfied = true

	record.next = (
		null
		if head.data.satisfied
		else ADDRESS_NEXT_OPTION.stmt
	)

func _next(player: PennyPlayer, record: Penny.Record) -> Stmt:
	return record.next if record.next else get_stmt_in_order()
