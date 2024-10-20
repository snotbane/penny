
## No description
class_name StmtConditionalElif extends StmtConditional_

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)

func _get_keyword() -> StringName:
	return super._get_keyword() + ' elif'

func _validate() -> PennyException:
	if not (prev_in_chain is StmtConditionalIf or prev_in_chain is StmtConditionalElif):
		return create_exception("Expected if or elif before elif statement")
	return validate_as_expression()

func _evaluate_self(host: PennyHost) -> Variant:
	## May return TRUE, FALSE, or NULL
	if host.expecting_conditional:
		return expr.evaluate(host)
	return null

func _should_skip(record: Record) -> bool:
	return not (record.host.expecting_conditional and record.attachment)
