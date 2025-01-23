
class_name StmtPrint extends StmtExpr


func _get_verbosity() -> Verbosity:
	return Verbosity.DEBUG_MESSAGES


func _execute(host: PennyHost) :
	var value = expr.evaluate(self.context)
	var message := str(value)
	print(message)
	return self.create_record(host, message)


# func _create_history_listing(record: Record) -> HistoryListing:
# 	var result := super._create_history_listing(record)
# 	result.message_label.text = record.data
# 	return result
