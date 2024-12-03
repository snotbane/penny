
## No description
class_name StmtConditionalMatch extends StmtConditional

var match_header_stmt : StmtMatch

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return super._get_keyword() + ' match'


func _get_verbosity() -> Verbosity:
	return super._get_verbosity()


# func _validate_self() -> PennyException:
# 	return validate_as_expression()


func _validate_self_post_setup() -> void:
	super._validate_self_post_setup()
	match_header_stmt = self.prev_in_lower_depth


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


# func _execute(host: PennyHost) :
# 	return super._execute(host)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt:
# 	return super._next(record)


func _evaluate_self(host: PennyHost) -> Variant:
	## May return TRUE, FALSE, or NULL
	if host.expecting_conditional:
		return Expr.type_safe_equals(match_header_stmt.expr.evaluate(), self.expr.evaluate())
	return null


func _should_skip(record: Record) -> bool:
	return not (record.host.expecting_conditional and record.attachment)
