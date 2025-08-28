## Moves execution to a specified label, and then returns here when that branch has been exhausted.
class_name StmtJumpCall extends StmtJump

func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]call : [/color][color=lawn_green]%s[/color][/code]" % Penny.get_value_as_bbcode_string(label_name)


func _prep(record: Record) -> void:
	super._prep(record)
	record.host.call_stack.push_back(next_in_order)

