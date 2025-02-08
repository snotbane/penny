
class_name StmtPrint extends StmtExpr


func _get_verbosity() -> Verbosity:
	return Verbosity.DEBUG_MESSAGES


func _execute(host: PennyHost) :
	var value = expr.evaluate(self.context)
	var message := str(value)
	print(message)
	return self.create_record(host, message)


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]print : [/color][color=light_gray]%s[/color][/code]" % record.data
