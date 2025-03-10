
## No description
class_name StmtOpen extends StmtNode


func _execute(host: PennyHost) :
	await self.open_subject(host)
	return self.create_record(host)


func _undo(record: Record) -> void:
	self.subject_node.queue_free()


func _redo(record: Record) -> void:
	self.open_subject(record.host, false)


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]open : [/color]%s[/code]" % Penny.get_value_as_bbcode_string(subject)
