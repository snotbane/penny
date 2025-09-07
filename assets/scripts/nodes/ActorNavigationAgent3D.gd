
class_name ActorNavigationAgent3D extends NavigationAgent3D

enum {
	IDLING,
	MOVING,
}

signal desired_move(direction: Vector3)

@export var nav_timer_duration : float = 1.0

@onready var parent : Node3D = get_parent()
var move_target : Node3D
var nav_timer : Timer

var state : int

func _ready() -> void:
	nav_timer = Timer.new()
	nav_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	nav_timer.wait_time = nav_timer_duration
	nav_timer.autostart = true
	nav_timer.timeout.connect(refresh_target_position)
	add_child(nav_timer)

	target_reached.connect(stop)

	sequence()

func sequence() -> void:
	if not has_method(&"_sequence"): return
	while is_inside_tree():	await call(&"_sequence")

func wait(duration_seconds: float) :
	await get_tree().create_timer(duration_seconds).timeout

func refresh_target_position() -> void:
	if not move_target: return

	target_position = move_target.global_position

	match state:
		IDLING:
			desired_move.emit(Vector3.ZERO)
		MOVING:
			var displacement := (get_next_path_position() - parent.global_position) * Vector3(1, 0, 1)
			desired_move.emit(displacement.normalized())


func stop() -> void:
	desired_move.emit(Vector3.ZERO)

