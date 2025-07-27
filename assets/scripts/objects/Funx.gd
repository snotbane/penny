extends RefCounted
class_name Funx

var host : PennyHost
var wait : bool

func _init(__host__: PennyHost = null, __wait__: bool = false) -> void:
	host = __host__
	wait = __wait__
