@tool class_name Superellipse extends ShapeBuilder2D

enum {
	GROW_NONE,
	GROW_X,
	GROW_Y,
	GROW_MIN,
	GROW_MAX,
}

class Data extends RefCounted:
	var superellipse: Variant
	var e: float
	var a: float
	var b: float
	var point_count: int
	var point_count_reciprocal: float


	func _init(__superellipse: Variant) -> void:
		superellipse = __superellipse
		e = 1.0 / ( superellipse.super_power * superellipse.super_power )
		a = superellipse.size.x * 0.5
		b = superellipse.size.y * 0.5
		point_count = floori(superellipse.resolution * RESOLUTION_SCALAR * (superellipse.size.x + superellipse.size.y))
		point_count_reciprocal = 1.0 / point_count


	func get_vector_array() -> PackedVector2Array:
		var result := PackedVector2Array()
		result.resize(point_count)
		return result


	func get_points() -> PackedVector2Array:
		var result := get_vector_array()
		for i in point_count:
			result[i] = superellipse._calculate_point(i, self)
		return result


	func get_uvs() -> PackedVector2Array:
		var result := get_vector_array()
		for i in point_count:
			result[i] = superellipse._calculate_uv(i, self)
		return result

	func get_texture() -> Texture2D:
		return superellipse._calculate_texture(self)


const RESOLUTION_SCALAR := 0.0025

var _resolution : int = 10
@export_range(1, 20, 1, "or_greater") var resolution : int = 10 :
	get: return _resolution
	set(value):
		if _resolution == value: return
		_resolution = value
		queue_redraw()

var _size : Vector2 = Vector2.ONE
@export var size : Vector2 = Vector2.ONE :
	get: return _size
	set(value):
		if _size == value: return
		_size = value
		_proportional_vector_refresh()
		queue_redraw()


var _super_power : float = 1.0
## Exponent to use for the superellipse.
@export_range(0.0, 10.0, 0.01, "or_greater") var super_power : float = 1.0 :
	get: return _super_power
	set(value):
		if _super_power == value: return
		_super_power = value
		queue_redraw()

var _proportional_vector : Vector2
var _proportional : bool = false
## If enabled, the superellipse's corners will be proportionally rounded.
@export var proportional : bool = false :
	get: return _proportional
	set(value):
		if _proportional == value: return
		_proportional = value
		_proportional_vector_refresh()

		queue_redraw()
func _proportional_vector_refresh() -> void:
	_proportional_vector = Vector2(
		size.y / size.x if size.x > size.y else 1.0,
		size.x / size.y if size.y > size.x else 1.0
	) if _proportional else Vector2.ONE


func _ready() -> void:
	super._ready()
	_proportional_vector_refresh()


func _draw() -> void:
	var data := Data.new(self)
	draw_colored_polygon(data.get_points(), self.color, data.get_uvs(), data.get_texture())
	# self.draw_mesh(Geometry2D.triangulate_polygon())


func _calculate_point(idx: int, data: Data) -> Vector2:
	var theta := TAU * idx * data.point_count_reciprocal
	var cos_t := cos(theta)
	var sin_t := sin(theta)

	return Vector2(
		data.a * signf(cos_t) * pow(absf(cos_t), data.e * _proportional_vector.x),
		data.b * signf(sin_t) * pow(absf(sin_t), data.e * _proportional_vector.y)
	)


func _calculate_uv(idx: int, data: Data) -> Vector2:
	return Vector2()


func _calculate_texture(data: Data) -> Texture2D:
	return null
