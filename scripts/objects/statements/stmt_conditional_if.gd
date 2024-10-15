
## No description
class_name StmtConditionalIf extends StmtConditional_

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)

func _get_keyword() -> StringName:
	return super._get_keyword() + ' if'

func _validate() -> PennyException:
	return validate_as_expression()

func _evaluate_self(host: PennyHost) -> Variant:
	## Always returns TRUE or FALSE
	return host.evaluate_expression_as_boolean(tokens)

func _should_skip(record: Record) -> bool:
	return not record.attachment
