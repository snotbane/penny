
## Speaks nothing. Hears nothing. Sees nothing. Is nothing.
class_name StmtLabel extends Stmt

func _get_keyword() -> StringName:
	return "label"

func _get_verbosity() -> int:
	return 3

func _load() -> void:
	if Penny.labels.has(tokens[0].value):
		PennyException.new("Label %s already exists" % tokens[0]).push()
	else:
		Penny.labels[tokens[0].value] = address

func _execute(host: PennyHost) -> Record:
	return super._execute(host)

func _undo(record: Record) -> void:
	pass

func _validate() -> PennyException:
	return validate_as_identifier_only()
