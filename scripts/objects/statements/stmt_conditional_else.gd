
## No description
class_name StmtConditionalElse extends StmtConditional


# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'else'


func _validate_self() -> PennyException:
	return validate_as_no_tokens()


# func _validate_self_post_setup() -> void:
# 	super._validate_self_post_setup()


func _validate_cross() -> PennyException:
	if not (prev_in_same_depth is StmtConditionalIf or prev_in_same_depth is StmtConditionalElif or prev_in_same_depth is StmtConditionalMatch):
		return create_exception("Expected if, elif, or match condition before else statement")
	return null


func _evaluate_self(host: PennyHost) -> Variant:
	## Always return TRUE or NULL
	if host.expecting_conditional:
		return true
	return null


func _should_skip(record: Record) -> bool:
	return not record.host.expecting_conditional
