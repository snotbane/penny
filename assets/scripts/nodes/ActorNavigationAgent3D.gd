
class_name ActorNavigationAgent3D extends NavigationAgent3D

enum {
	IDLING,
	MOVING,
}

signal desired_move(direction: Vector3)

@onready var parent : Node3D = get_parent()
@onready var _temp_target := Node3D.new()

@export var nav_timer_duration : float = 1.0

var _move_target : Node3D
var move_target : Node3D :
	get: return _move_target
	set(value):
		if _move_target == value: return

		if _move_target == _temp_target:
			_temp_target.get_parent().remove_child(_temp_target)

		_move_target = value

		if _move_target == _temp_target:
			parent.add_sibling(_temp_target)

var nav_timer : Timer

var state : int

func _ready() -> void:
	nav_timer = Timer.new()
	nav_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	nav_timer.wait_time = nav_timer_duration
	nav_timer.autostart = true
	nav_timer.timeout.connect(refresh_target_position)
	add_child(nav_timer)

	target_reached.connect(stop_moving)

	sequence()

func sequence() -> void:
	while is_inside_tree():	await _sequence()
func _sequence() : await wait(3600)

func wait(duration_seconds: float) :
	await get_tree().create_timer(duration_seconds).timeout


func create_loose_local_target(pos: Vector3) -> void:
	_temp_target.position = pos
	move_target = _temp_target


func refresh_target_position() -> void:
	if not move_target: return

	target_position = move_target.global_position

	match state:
		IDLING:
			desired_move.emit(Vector3.ZERO)
		MOVING:
			var displacement := (get_next_path_position() - parent.global_position) * Vector3(1, 0, 1)
			desired_move.emit(displacement.normalized())

func start_moving(target: Variant = null) -> void:
	if target is Node3D:
		move_target = target
	elif target is Vector3:
		create_loose_local_target(target)
	elif target != null:
		assert(false, "Agent's dynamic target must be a Vector3 or Node3D.")

	state = MOVING if move_target != null else IDLING

func stop_moving() -> void:
	state = IDLING

