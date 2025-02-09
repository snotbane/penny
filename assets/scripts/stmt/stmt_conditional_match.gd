
## No description
class_name StmtConditionalMatch extends StmtConditional

var match_header_stmt : StmtMatch


func _evaluate_self(host: PennyHost) -> Variant:
	## May return TRUE, FALSE, or NULL
	if host.expecting_conditional:
		return Expr.type_safe_equals(self.prev_in_lower_depth.expr.evaluate(), self.expr.evaluate())
	return null


func _should_passover(record: Record) -> bool:
	return not (record.host.expecting_conditional and record.data)
