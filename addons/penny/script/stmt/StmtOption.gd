@tool
class_name StmtOption
extends StmtBranch

@export_storage
var address_head: Address

@export_storage
var address_next_option: Address

@export_storage
var address_skip: Address


func get_head_record(player: PennyPlayer) -> Penny.Record:
	return player.ledger.find_recent_record_from_stmt(address_head.stmt)


func _compile(script: PennyScript) -> void:
	address_head = Address.new(get_stmt_idx_in_depth_less_than(-1))
	address_next_option = Address.new(get_stmt_idx_in_depth_less_than_or_equal(+1))
	address_skip = Address.new(get_stmt_idx_in_depth_less_than(+1))


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	var head_record := get_head_record(player)
	if head_record.data.satisfied:
		record.data = null
		record.next = address_skip.stmt
		return

	super._draw(player, record)

	if Penny.Express.type_and_value_equals(head_record.data.result, record.data):
		head_record.data.satisfied = true

	record.next = (
		get_stmt_next_in_order()
		if head_record.data.satisfied
		else address_next_option.stmt
	)
