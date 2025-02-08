
class_name StmtLabel extends Stmt

var label_name : StringName


func _populate(tokens: Array) -> void:
	label_name = tokens[0].value


func _reload() -> void :
	if Penny.labels.has(label_name):
		owner.errors.push_back("Label '%s' already exists in the current Penny environment." % label_name)
	else:
		Penny.labels[label_name] = self


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]label : [/color][color=lawn_green]%s[/color][/code]" % Penny.get_value_as_bbcode_string(label_name)