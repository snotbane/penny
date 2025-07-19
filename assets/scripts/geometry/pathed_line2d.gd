## A [Line2D] that deforms along its parent [Path2D], with an optional shape [Path2D].
@tool class_name PathedLine2D extends Line2D


@onready var parent_path : Path2D = self.get_parent()

## Optional shape path that the line will follow. This path can be any length and contain any number of points, but keep in mind that the final point in the path will define the length of the shape.
@export var shape_path : Path2D

var _stretch_shape_to_fit : bool = false
## If enabled, the [member shape_path] will only appear at the head of the curve; after the length of [member shape_path] has been reached, [member parent_path] will be followed exclusively.
@export var stretch_shape_to_fit : bool = false :
	get: return _stretch_shape_to_fit
	set(value):
		_stretch_shape_to_fit = value
		refresh_deform_function()
var deform_function : Callable
func refresh_deform_function() -> void:
	deform_function = deform_point_with_shape_stretch if stretch_shape_to_fit else deform_point_with_shape_absolute

@export var shape_even : bool = true
@export var parent_even : bool = false

@export_range(0, 10, 1, "or_greater") var tessellate_resolution : int = 5
@export_range(0, 180, 0.1) var tessellate_tolerance_degrees : float = 4.0
@export_range(0, 100, 0.1, "or_greater") var tessellate_tolerance_length : float = 20.0

@export_range(0.0, 1.0, 0.01) var length_percent := 1.0

var parent_length : float
var shape_length : float
var basis_length : float
var parent_to_basis_ratio : float


var shape_segments : int :
	get: return shape_path.curve.point_count - 1 if shape_path else 1


func _ready() -> void:
	refresh_deform_function()


func _process(delta: float) -> void:
	self.clear_points()
	if length_percent <= 0.0: return

	last_point = Vector2.ZERO
	total_length = 0.0
	point_lengths = PackedFloat64Array()

	parent_length = parent_path.curve.get_baked_length()

	if shape_path:
		shape_length = shape_path.curve.get_baked_length()
		basis_length = shape_path.curve.get_point_position(shape_path.curve.point_count - 1).x
		parent_to_basis_ratio = parent_length / basis_length

		var shape_points : PackedVector2Array = self.tessellate(shape_path, shape_even) if shape_path else PackedVector2Array()
		for i in shape_points.size():
			self.add_point_and_length(deform_function.call(i, shape_points[i]))
	else:
		shape_length = 0.0
		basis_length = 0.0
		parent_to_basis_ratio = INF

	if not shape_path or (not stretch_shape_to_fit and parent_to_basis_ratio > 1.0):
		var extra_points := self.tessellate(parent_path, parent_even)
		for i in extra_points:
			if parent_path.curve.get_closest_offset(i) / basis_length < 1.0: continue
			self.add_point_and_length(i)

	if length_percent < 1.0:
		var b_length := 0.0
		var a_length := 0.0
		var insert_index := 0
		for i in point_lengths.size():
			b_length += point_lengths[i]
			if b_length >= total_length * length_percent:
				insert_index = i; break
			a_length = b_length

		var insert_position : Vector2 = lerp(self.get_point_position(insert_index - 1), self.get_point_position(insert_index), inverse_lerp(a_length, b_length, length_percent * total_length))
		self.add_point(insert_position, insert_index)

		var remove_point_count := self.get_point_count() - insert_index - 1
		for i in remove_point_count:
			self.remove_point(insert_index + 1)

var last_point : Vector2
var point_lengths : PackedFloat64Array
var total_length : float
func add_point_and_length(pos: Vector2, idx: int = -1) -> void:
	var this_length := pos.distance_to(last_point)
	total_length += this_length
	point_lengths.push_back(this_length)
	self.add_point(pos, idx)
	last_point = pos


func deform_point_with_shape_stretch(point_index: int, point_position: Vector2) -> Vector2:
	var shape_sample := shape_path.curve.get_closest_offset(point_position)
	var shape_transform := shape_path.curve.sample_baked_with_rotation(shape_sample)

	var parent_sample := shape_transform.origin.x * parent_to_basis_ratio
	var parent_transform := parent_path.curve.sample_baked_with_rotation(parent_sample)

	return parent_transform.origin + (parent_transform.y * shape_transform.origin.y)


func deform_point_with_shape_absolute(point_index: int, point_position: Vector2) -> Vector2:
	var shape_sample := shape_path.curve.get_closest_offset(point_position)
	var shape_transform := shape_path.curve.sample_baked_with_rotation(shape_sample)

	var parent_sample := shape_transform.origin.x * parent_to_basis_ratio * minf(1.0 / parent_to_basis_ratio, 1.0)
	var parent_transform := parent_path.curve.sample_baked_with_rotation(parent_sample)

	return parent_transform.origin + (parent_transform.y * shape_transform.origin.y * minf(parent_to_basis_ratio, 1.0))


func tessellate(path: Path2D, even: bool) -> PackedVector2Array:
	if even:
		return path.curve.tessellate_even_length(tessellate_resolution, tessellate_tolerance_length)
	else:
		return path.curve.tessellate(tessellate_resolution, tessellate_tolerance_degrees)
