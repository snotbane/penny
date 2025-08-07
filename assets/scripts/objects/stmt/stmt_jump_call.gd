
class_name StmtJumpCall extends StmtJump


func _pre_execute(record: Record) -> void:
	super._pre_execute(record)
	record.host.call_stack.push_back(next_in_order)


func _undo(record: Record) -> void:
	record.host.call_stack.pop_back()


func _redo(record: Record) -> void:
	record.host.call_stack.push_back(next_in_order)


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]call : [/color][color=lawn_green]%s[/color][/code]" % Penny.get_value_as_bbcode_string(label_name)
