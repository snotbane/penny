@tool
extends Resource

@export_storage
var idx: int

var stmt: Stmt


func _init(__idx__: int = -1) -> void:
	idx = __idx__


func populate(script: PennyScript) -> void:
	stmt = script.stmts[idx] if idx >= 0 and idx < script.stmts.size() else null
