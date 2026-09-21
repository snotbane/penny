@tool
class_name StmtOption
extends StmtBranch

@export_storage
var when_express: Variant

@export_storage
var address_head: Address

@export_storage
var address_next_option: Address

@export_storage
var address_skip: Address



func get_head_record(player: PennyPlayer) -> Penny.Record:
	return player.ledger.find_recent_record_from_stmt(address_head.stmt)


func _populate(tokens: Array) -> void:
	if tokens.back().type == PennyScript.Token.Type.OPERATOR and tokens.back().type == PennyScript.Token.Operator.ACCESS:
		tokens.pop_back()

	var when_split_idx: int = -1
	for i in tokens.size():
		if tokens[i].type == PennyScript.Token.Type.KEYWORD and tokens[i].value == PennyScript.Token.Keyword.WHEN:
			when_split_idx = i
			assert(
				when_split_idx > 0 and when_split_idx < tokens.size() - 1,
				"'when' modifier must appear between two expressions."
			)
			break

	if when_split_idx == -1:
		express = Penny.Express.new_or_literal_from_tokens_destructive(tokens)
		when_express = null

	else:
		express = Penny.Express.new_or_literal_from_tokens_destructive(tokens.slice(0, when_split_idx))
		when_express = Penny.Express.new_or_literal_from_tokens_destructive(tokens.slice(when_split_idx + 1))
		tokens.clear()


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

	if when_express != null:
		var when_value = Penny.Evaluable.evaluate_any(when_express, context_value_from_recent)
		if not when_value:
			record.data = null
			record.next = address_next_option.stmt
			return

	super._draw(player, record)

	if Penny.Express.type_and_value_equals(head_record.data.result, record.data):
		head_record.data.satisfied = true

	record.next = (
		get_stmt_next_in_order()
		if head_record.data.satisfied
		else address_next_option.stmt
	)
