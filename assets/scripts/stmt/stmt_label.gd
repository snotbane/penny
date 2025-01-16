
class_name StmtLabel extends Stmt

var label_name : StringName

func _populate(tokens: Array) -> void:
	label_name = tokens[1].value


func _reload() -> void :
	if Penny.labels.has(label_name):
		owner.errors.push_back("Label '%s' already exists in the current Penny environment." % label_name)
	else:
		Penny.labels[label_name] = self