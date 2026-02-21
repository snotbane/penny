## Function context. Tells us about which host called the function and whether or not it is awaited.
class_name Funx extends RefCounted

var host : PennyHost
var wait : bool
var record : Record

func _init(__host__: PennyHost = null, __wait__: bool = false) -> void:
	host = __host__
	wait = __wait__
