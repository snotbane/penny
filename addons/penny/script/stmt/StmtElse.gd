@tool
class_name StmtElse
extends StmtBranch

@export_storage
var address_prev: Address

@export_storage
var address_skip: Address


func _compile(script: PennyScript) -> void:
	var prev_idx := get_stmt_idx_in_depth_equal(-1)
	var prev_stmt := get_stmt_in_owner(prev_idx)

	if prev_stmt is StmtOption:
		address_prev = prev_stmt.address_head
		address_skip = Address.new(get_stmt_idx_in_depth_less_than(+1))

	elif prev_stmt is StmtElif or prev_stmt is StmtIf:
		address_prev = Address.new(prev_idx)
		address_skip = Address.new(get_stmt_idx_in_depth_less_than_or_equal(+1))

	elif prev_stmt == null:
		prev_idx = get_stmt_idx_in_depth_less_than(-1)
		assert(
			get_stmt_in_owner(prev_idx) is StmtMatch,
			"StmtElse must be preceeded by a 'if', 'elif', 'match' or a match option."
		)
		address_skip = Address.new(get_stmt_idx_in_depth_less_than(+1))

	else:
		assert(
			false,
			"StmtElse must be preceeded by a 'if', 'elif', 'match' or a match option."
		)
		address_skip = Address.new(get_stmt_idx_in_depth_less_than_or_equal(+1))


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	assert(record.data == null)

	var prev_record := player.ledger.find_recent_record_from_stmt(address_prev.stmt)
	record.next = (
		address_skip.stmt
		if prev_record.data.satisfied
		else get_stmt_next_in_order()
	)

	if prev_record.stmt is StmtMatch:
		prev_record.data.satisfied = true
