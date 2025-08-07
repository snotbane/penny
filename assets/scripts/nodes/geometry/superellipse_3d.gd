@tool class_name Superellipse3D extends CSGPolygon3D

var _resolution : int = 10
@export_range(1, 20, 1, "or_greater") var resolution : int = 10 :
	get: return _resolution
	set(value):
		if _resolution == value: return
		_resolution = value

var _size : Vector2 = Vector2.ONE
@export var size : Vector2 = Vector2.ONE :
	get: return _size
	set(value):
		if _size == value: return
		_size = value
		_proportional_vector_refresh()


var _super_power : float = 1.0
## Exponent to use for the superellipse.
@export_range(0.0, 10.0, 0.01, "or_greater") var super_power : float = 1.0 :
	get: return _super_power
	set(value):
		if _super_power == value: return
		_super_power = value

var _proportional_vector : Vector2
var _proportional : bool = false
## If enabled, the superellipse's corners will be proportionally rounded.
@export var proportional : bool = false :
	get: return _proportional
	set(value):
		if _proportional == value: return
		_proportional = value
		_proportional_vector_refresh()
func _proportional_vector_refresh() -> void:
	_proportional_vector = Vector2(
		size.y / size.x if size.x > size.y else 1.0,
		size.x / size.y if size.y > size.x else 1.0
	) if _proportional else Vector2.ONE


func _ready() -> void:
	# super._ready()
	_proportional_vector_refresh()


func _process(delta: float) -> void:
	var data := Superellipse.Data.new(self)
	self.polygon = data.get_points()


func _calculate_point(idx: int, data: Superellipse.Data) -> Vector2:
	var theta := TAU * idx * data.point_count_reciprocal
	var cos_t := cos(theta)
	var sin_t := sin(theta)

	return Vector2(
		data.a * signf(cos_t) * pow(absf(cos_t), data.e * _proportional_vector.x),
		data.b * signf(sin_t) * pow(absf(sin_t), data.e * _proportional_vector.y)
	)


func _calculate_uv(idx: int, data: Superellipse.Data) -> Vector2:
	return Vector2()


func _calculate_texture(data: Superellipse.Data) -> Texture2D:
	return null

