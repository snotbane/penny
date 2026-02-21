## Defines an expression which will be evaluated, and then execution will route the child branch whose value matches the result of that expresssion.
class_name StmtMatch extends StmtExpr

func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY

func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]match : [/color]%s[/code]" % Penny.get_value_as_bbcode_string(expr)


func _prep(record: Record) -> void:
	record.host.expecting_conditional = true
	super._prep(record)
