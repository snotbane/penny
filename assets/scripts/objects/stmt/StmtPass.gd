## Speaks nothing. Hears nothing. Sees nothing. Is nothing.
class_name StmtPass extends Stmt

func _get_verbosity() -> Verbosity:
	return Verbosity.IGNORED

func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]pass[/color][/code]"
