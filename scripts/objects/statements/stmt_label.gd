
## Speaks nothing. Hears nothing. Sees nothing. Is nothing.
class_name StmtLabel extends Stmt_

func _get_keyword() -> StringName:
	return "label"

func _get_verbosity() -> int:
	return Verbosity.IGNORED

func _load() -> PennyException:
	if Penny.labels.has(tokens[0].value):
		return create_exception("Label '%s' already exists (%s)" % [tokens[0].value, Penny.get_stmt_from_label(tokens[0].value).file_address.pretty_string])
	else:
		Penny.labels[tokens[0].value] = address
		return super._load()

func _execute(host: PennyHost) -> Record:
	return super._execute(host)

func _undo(record: Record) -> void:
	pass

func _validate() -> PennyException:
	return validate_as_identifier_only()
