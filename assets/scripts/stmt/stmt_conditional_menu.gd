
## No description
class_name StmtConditionalMenu extends StmtConditional

var expected_path : Path
var is_raw_text_option : bool :
	get: return expr._evaluate(null) is not Path


func _populate(tokens: Array) -> void:
	super._populate(tokens)

	if is_raw_text_option:
		expected_path = Path.new(["_" + str(self.index_in_same_depth_chain)], true)
	else:
		expected_path = expr._evaluate(null)


func _evaluate_self(host: PennyHost) -> Variant:
	if not host.expecting_conditional:
		return null
	if self.prev_in_lower_depth.response is Evaluable:
		return self.prev_in_lower_depth.response.evaluate() == expected_path.evaluate()
	else:
		return false


func _should_passover(record: Record) -> bool:
	return not (record.host.expecting_conditional and record.data)
