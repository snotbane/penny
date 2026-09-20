extends Resource

@export_storage
var stmt: Stmt

@export_storage
var next: Stmt

@export_storage
var context_cell: Penny.Cell

@export_storage
var data: Variant


func _to_string() -> String:
	var result := str(stmt)
	if data != null:
		result += " :: %s" % str(data)
	return result


func _populate(__stmt__: Stmt) -> void:
	context_cell = null
	stmt = __stmt__


func execute(player: PennyPlayer):
	return await stmt.execute(player, self)
