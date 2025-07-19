@tool
extends PrimitiveMesh
class_name SupereggMesh

var _resolution : Vector2i
@export var resolution : Vector2i = Vector2i.ONE * 16 :
	get: return _resolution
	set(value):
		value = Vector2i(
			maxi(value.x, 2),
			maxi(value.y, 2)
		)
		_resolution = value
		request_update()
var _box_size : Vector3
@export var box_size : Vector3 = Vector3.ONE + Vector3.RIGHT :
	get: return _box_size
	set(value):
		value = Vector3(
			maxf(value.x, 0.0),
			maxf(value.y, 0.0),
			maxf(value.z, 0.0),
		)
		_box_size = value
		request_update()
var _super_power : float
@export_range(0.0, 10.0, 0.01, "or_greater") var super_power : float = 2.0 :
	get: return _super_power
	set(value):
		_super_power = value
		request_update()
var _proportional_x : bool
@export var proportional_x : bool = false :
	get: return _proportional_x
	set(value):
		if _proportional_x == value: return
		_proportional_x = value
		request_update()
var _proportional_z : bool
@export var proportional_z : bool = false :
	get: return _proportional_z
	set(value):
		if _proportional_z == value: return
		_proportional_z = value
		request_update()

func _create_mesh_array() -> Array:
	var proportional_vector_x : Vector3 = Vector3(
		box_size.y / box_size.x if box_size.x > box_size.y else 1.0,
		box_size.x / box_size.y if box_size.y > box_size.x else 1.0,
		# 1.0,
		1.0
	) if proportional_x else Vector3.ONE
	var proportional_vector_z : Vector3 = Vector3(
		1.0,
		1.0,
		# box_size.z / box_size.y if box_size.y > box_size.z else 1.0,

		box_size.y / box_size.z if box_size.z > box_size.y else 1.0,
	) if proportional_z else Vector3.ONE
	var proportional_vector := proportional_vector_x * proportional_vector_z
	# var proportional_vector := Vector3(
	# 	box_size.y / box_size.x if box_size.x > box_size.y else 1.0,
	# 	(box_size.x / box_size.y if box_size.y > box_size.x else 1.0) * (box_size.z / box_size.y if box_size.y > box_size.z else 1.0),
	# 	box_size.y / box_size.z if box_size.z > box_size.y else 1.0
	# )


	var resolution_reciprocal := Vector2.ONE / Vector2(resolution)
	var super_power_reciprocal := 2.0 / super_power

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indeces := PackedInt32Array()

	vertices.resize((resolution.x + 1) * (resolution.y + 1))
	normals.resize(vertices.size())
	uvs.resize(vertices.size())

	for i in resolution.x + 1:
		var phi := PI * i * resolution_reciprocal.x
		var sin_phi := sin(phi)
		var cos_phi := cos(phi)
		var x_sign : float = -sign(cos_phi)
		var x : float = box_size.x * x_sign * pow(abs(cos_phi), super_power_reciprocal * proportional_vector.x)

		var idx := 0
		for j in resolution.y:
			idx = (i * (resolution.y + 1)) + j

			var theta := TAU * j * resolution_reciprocal.y
			var sin_theta := cos(theta)
			var cos_theta := sin(theta)

			var z_val := cos_theta * sin_phi
			var y_val := sin_theta * sin_phi

			var z : float = box_size.z * sign(z_val) * pow(abs(z_val), super_power_reciprocal * proportional_vector.z)
			var y : float = box_size.y * sign(y_val) * pow(abs(y_val), super_power_reciprocal * proportional_vector.y)

			var v := Vector3(x, y, z)
			var uv := Vector2(
				float(j) / float(resolution.y),
				float(i) / float(resolution.x)
			)

			vertices[idx] = v
			normals[idx] = v.normalized()
			uvs[idx] = uv

		idx += 1
		vertices[idx] = vertices[i * (resolution.y + 1)]
		normals[idx] = normals[i * (resolution.y + 1)]
		uvs[idx] = uvs[i * (resolution.y + 1)]
	for j in resolution.y + 1:
		var idx := (resolution.x * (resolution.y + 1)) + j
		vertices[idx] = Vector3(
			vertices[idx].x,
			vertices[j].y,
			vertices[j].z,
		)
		normals[idx] = vertices[idx].normalized()
		uvs[idx] = Vector2(
			float(j) / float(resolution.y),
			1.0
		)

	indeces.resize((resolution.x + 1) * (resolution.y + 1) * 6)

	for i in resolution.x:
		for j in resolution.y:
			var idx := ((i * resolution.y) + j) * 6

			var p1 := i * (resolution.y + 1) + j
			var p2 := p1 + resolution.y + 1

			indeces[idx    ] = p1
			indeces[idx + 1] = p2
			indeces[idx + 2] = p1 + 1

			indeces[idx + 3] = p1 + 1
			indeces[idx + 4] = p2
			indeces[idx + 5] = p2 + 1

	var arrays := Array()
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indeces

	return arrays
