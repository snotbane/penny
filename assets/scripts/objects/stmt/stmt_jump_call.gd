
class_name StmtJumpCall extends StmtJump


func _prep(record: Record) -> void:
	super._prep(record)
	record.host.call_stack.push_back(next_in_order)


func _undo(record: Record) -> void:
	super._undo(record)


func _redo(record: Record) -> void:
	super._redo(record)


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]call : [/color][color=lawn_green]%s[/color][/code]" % Penny.get_value_as_bbcode_string(label_name)
