class_name CrossOperation extends Timer

signal finished

var start_transform : Variant
var destination : Variant
var curve : Curve
var global : bool

@onready var parent : Node = get_parent()

var origin_position : Vector3 :
	get: return start_transform.origin

var destination_position : Vector3 :
	get: return (destination.global_position if global else destination.position) if destination is Node else destination

func _init(__destination__, __curve__: Curve, __duration__: float = 1.0, __global__: bool = false) -> void:
	destination = __destination__
	curve = __curve__
	global = __global__
	wait_time = __duration__

	timeout.connect(finish)


func _ready() -> void:
	start_transform = parent.global_transform if global else parent.transform


func _process(delta: float) -> void:
	if is_stopped(): return

	var alpha := 1.0 - (time_left / wait_time)
	set_parent_position(lerp(origin_position, destination_position, curve.sample_baked(alpha)))


func set_parent_position(pos) -> void:
	if global:	parent.global_position = pos
	else:		parent.position = pos


func finish() -> void:
	stop()
	set_parent_position(destination_position)
	finished.emit()
	queue_free()

