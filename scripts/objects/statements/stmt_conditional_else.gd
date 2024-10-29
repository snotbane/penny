
## No description
class_name StmtConditionalElse extends StmtConditional_


func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)


func _get_keyword() -> StringName:
	return 'else'


func _validate_self() -> PennyException:
	return validate_as_no_tokens()


# func _validate_self_post_setup() -> void:
# 	super._validate_self_post_setup()


func _validate_cross() -> PennyException:
	if not (prev_in_chain is StmtConditionalIf or prev_in_chain is StmtConditionalElif):
		return create_exception("Expected if or elif before else statement")
	return null


func _evaluate_self(host: PennyHost) -> Variant:
	## Always return TRUE or NULL
	if host.expecting_conditional:
		return true
	return null


func _should_skip(record: Record) -> bool:
	return not record.host.expecting_conditional
