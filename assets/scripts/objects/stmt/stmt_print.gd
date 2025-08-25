
class_name StmtPrint extends StmtExpr


func _get_verbosity() -> Verbosity:
	return Verbosity.DEBUG_MESSAGES


func _prep(record: Record) -> void:
	record.data.merge({
		&"message": str(expr.evaluate(self.context))
	})


func _execute(record: Record) :
	print("[Penny] :: ", record.data[&"message"])


# func _undo(record: Record) -> void:
# 	super._undo(record)

func _redo(record: Record) -> void:
	super._redo(record)
	_execute(record)


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]print : [/color][color=light_gray]%s[/color][/code]" % record.data
