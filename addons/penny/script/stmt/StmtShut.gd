@tool
class_name StmtShut
extends StmtPass

@export_storage
var despawn: bool

func _init(__despawn__: bool = true) -> void:
	despawn = __despawn__


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	record.data = player.ledger.most_recent_dialog


func _execute(player: PennyPlayer, record: Penny.Record):
	if record.data:
		match despawn:
			true:
				await record.data.despawn(player, record)

			false:
				await record.data.exit(player, record)
