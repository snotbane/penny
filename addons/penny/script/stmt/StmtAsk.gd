@tool
class_name StmtAsk
extends StmtNodeInterface

@export_storage
var options: Array[Address] = []

@export_storage
var address_skip: Address

func _get_verbosity() -> Verbosity:
	return Verbosity.USER_FACING


func _get_node_key() -> StringName:
	return &"interface_ask"


func _populate(tokens: Array) -> void:
	if tokens.back().type == PennyScript.Token.Type.OPERATOR and tokens.back().type == PennyScript.Token.Operator.ACCESS:
		tokens.pop_back()

	super._populate(tokens)


func _compile(script: PennyScript) -> void:
	address_skip = Address.new(get_stmt_idx_in_depth_less_than_or_equal(+1))

	var nested_idxs := get_stmt_idxs_nested()
	options.resize(nested_idxs.size())
	for i in nested_idxs.size():
		options[i] = Address.new(nested_idxs[i])


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	super._draw(player, record)

	record.data.satisfied = true

	record.data.options = []
	record.data.options.resize(options.size())
	for i in options.size():
		assert(
			options[i].stmt is StmtOption,
			"Ask children can only be [StmtOption]s."
		)

		## This should be the same as what we do in [StmtExpress].
		var option_value : Variant = Penny.Evaluable.evaluate_any(options[i].stmt.express, context_value_from_recent)

		if option_value is Penny.Message:
			option_value = option_value.purified(record.data.subject)

		record.data.options[i] = option_value


func _execute(player: PennyPlayer, record: Penny.Record):
	await super._execute(player, record)

	record.next = (
		options[record.data.response].stmt.get_stmt_next_in_order()
		if record.data.response != null
		else address_skip.stmt
	)


func _next(player: PennyPlayer, record: Penny.Record) -> Stmt:
	return record.next
