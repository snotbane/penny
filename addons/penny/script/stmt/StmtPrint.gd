@tool
class_name StmtPrint
extends StmtExpress


func _get_verbosity() -> Verbosity:
	return Verbosity.DEBUG_MESSAGES


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	record.data = str(Penny.Evaluable.evaluate_any(express))


func _execute(player: PennyPlayer, record: Penny.Record) -> void:
	print("[ Penny :: %s ] %s" % [
		player.name,
		record.data,
	])
