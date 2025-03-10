
## No description
class_name StmtJump extends Stmt

var label_name : StringName


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _populate(tokens: Array) -> void:
	label_name = tokens[0].value


func _execute(host: PennyHost) :
	return self.create_record(host, label_name)


func _next(record: Record) -> Stmt:
	return Penny.get_stmt_from_label(record.data)


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]jump : [/color][color=lawn_green]%s[/color][/code]" % Penny.get_value_as_bbcode_string(label_name)
