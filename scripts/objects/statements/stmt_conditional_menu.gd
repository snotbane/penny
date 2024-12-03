
## No description
class_name StmtConditionalMenu extends StmtConditional

var menu_stmt : StmtMenu
var expected_path : Path
var is_raw_text_option : bool :
	get: return expr.evaluate_shallow(null) is not Path

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return super._get_keyword() + ' menu'


# func _get_verbosity() -> Verbosity:
# 	return super._get_verbosity()


func _validate_self() -> PennyException:
	return null


func _validate_self_post_setup() -> void:
	super._validate_self_post_setup()

	menu_stmt = self.prev_in_lower_depth

	if is_raw_text_option:
		expected_path = Path.from_single("_" + str(self.index_in_same_depth_chain))
	else:
		expected_path = expr.evaluate_shallow(null)


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


func _execute(host: PennyHost) :
	return super._execute(host)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt:
# 	return super._next(record)


func _evaluate_self(host: PennyHost) -> Variant:
	if not host.expecting_conditional:
		return null
	var response : Variant = menu_stmt.get_response(host)
	if response is Evaluable:
		return response.evaluate() == expected_path.evaluate()
	else:
		return false


func _should_skip(record: Record) -> bool:
	return not (record.host.expecting_conditional and record.attachment)
