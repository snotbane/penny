## Shorthand for closing the currently open dialog.
class_name StmtDialogClose extends StmtNode


func _execute(record: Record):
	await record.host.subject_context.historical_dialog.exit(Funx.new(record.host, true))

func _undo(record: Record) -> void:
	record.host.subject_context.historical_dialog.enter(Funx.new(record.host, false))

func _redo(record: Record) -> void:
	record.host.subject_context.historical_dialog.exit(Funx.new(record.host, false))
