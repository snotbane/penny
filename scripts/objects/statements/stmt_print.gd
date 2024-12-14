
class_name StmtPrint extends Stmt

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return "print"


func _get_verbosity() -> Verbosity:
	return Verbosity.DEBUG_MESSAGES


func _validate_self() -> PennyException:
	return validate_as_expression()


# func _validate_self_post_setup() -> void:
# 	pass


# func _validate_cross() -> PennyException:
# 	return null


func _execute(host: PennyHost) :
	var expr := Expr.from_tokens(tokens, self)
	var value = expr.evaluate(self.owning_object)
	var message := str(value)
	print(message)
	return self.create_record(host, message)


# func _undo(record: Record) -> void:
# 	pass


# func _next(record: Record) -> Stmt:
# 	return next_in_order


func _create_history_listing(record: Record) -> HistoryListing:
	var result := super._create_history_listing(record)
	result.message_label.text = record.data
	return result
