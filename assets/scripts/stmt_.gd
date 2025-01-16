
## Base class for all executable statemetnts.
class_name Stmt extends RefCounted

var owning_script : PennyScript
var index : int
var depth : int


## Called when Penny reloads all scripts. If any errors are produced, add them to [member owning_script]'s error list.
func reload() -> void: self._reload()
func _reload() -> void: pass