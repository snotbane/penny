@tool extends Path2D

enum {
	HEAD,
	TAIL
}

@onready var anchor : Control = self.get_parent() if not Engine.is_editor_hint() else null
@onready var line : PathedLine2D = $line_2d
@onready var line_width_base : float = line.width

@export var world_target : Node3D

var _profile_scale := Vector2.ONE
@export var profile_scale := Vector2.ONE :
	get: return _profile_scale
	set(value):
		_profile_scale = value

		if not line: return
		line.width = value.x * line_width_base
		line.length_percent = value.y

var _length_percent : float = 1.0
@export_range(0.0, 1.0, 0.001) var length_percent : float = 1.0 :
	get: return _length_percent
	set(value):
		if _length_percent == value: return
		_length_percent = value

		if line: line.length_percent = _length_percent

@export_subgroup("Motion")

@export var head_tangent_scale := Vector2.ONE
@export var head_position_scale := Vector2.RIGHT

var tail_in : Vector2
var tail_in_normal : Vector2

func _ready() -> void:
	tail_in = self.curve.get_point_in(TAIL)
	tail_in_normal = tail_in.normalized()

	profile_scale = profile_scale

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		self.global_position = Vector2.ZERO


		var target_position : Vector2 = self.get_viewport().get_camera_3d().unproject_position(world_target.global_position)

		var curve_length_ratio := self.curve.get_baked_length() / self.get_viewport().get_window().size.x
		var current_mouse_pos = target_position
		# var mouse_velocity = (current_mouse_pos - last_mouse_pos) / delta
		var mouse_velocity = current_mouse_pos - last_mouse_pos
		last_mouse_pos = current_mouse_pos

		jiggle_vel += mouse_velocity * influence
		jiggle_vel -= jiggle_pos * stiffness / curve_length_ratio
		jiggle_vel *= damping
		jiggle_pos += jiggle_vel * delta

		self.curve.set_point_position(TAIL, target_position)

		var in_distance := (self.curve.get_point_position(HEAD).x - self.curve.get_point_position(TAIL).x)
		var target_in_position = Vector2.RIGHT * in_distance
		self.curve.set_point_in(TAIL, target_in_position + jiggle_pos)

		self.curve.set_point_position(HEAD, anchor.get_global_rect().get_center() + (self.curve.get_point_position(TAIL) - anchor.get_global_rect().get_center()) * head_position_scale)
		self.curve.set_point_out(HEAD, (self.curve.get_point_position(TAIL) - self.curve.get_point_position(HEAD)) * head_tangent_scale)

		draw_pos = self.curve.get_point_position(TAIL) + self.curve.get_point_in(TAIL)
		queue_redraw()


var jiggle_pos := Vector2.ZERO
var jiggle_vel := Vector2.ZERO
@export var damping := 0.5
@export var stiffness := 1.0
var influence := 1.0

var last_mouse_pos := Vector2.ZERO
var draw_pos := Vector2.ZERO

func _draw() -> void:
	# draw_circle(draw_pos, 50.0, Color.RED)
	pass