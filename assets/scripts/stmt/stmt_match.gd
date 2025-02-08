
class_name StmtMatch extends StmtExpr


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _execute(host: PennyHost) :
	host.expecting_conditional = true
	return super._execute(host)


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]match : [/color]%s[/code]" % Penny.get_value_as_bbcode_string(expr)