
## No description
class_name StmtConditionalMenu extends StmtConditional_

var menu_stmt : StmtMenu
var expected_path : Path

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
	# expected_path = "_" + str(self.index_in_chain)


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


func _execute(host: PennyHost) -> Record:
	return super._execute(host)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt_:
# 	return super._next(record)


func _message(record: Record) -> Message:
	return super._message(record)


func _evaluate_self(host: PennyHost) -> Variant:
	if not host.expecting_conditional:
		return null
	return menu_stmt.get_response(host).evaluate(host.data_root) == expected_path.evaluate(host.data_root)


func _should_skip(record: Record) -> bool:
	return not (record.host.expecting_conditional and record.attachment)
