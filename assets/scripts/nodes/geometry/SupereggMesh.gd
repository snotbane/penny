@tool class_name SupereggMesh extends PrimitiveMesh

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
var _proportional : bool
@export var proportional : bool = false :
	get: return _proportional
	set(value):
		if _proportional == value: return
		_proportional = value
		request_update()
var _flip_normals : bool
@export var flip_normals : bool :
	get: return _flip_normals
	set(value):
		if _flip_normals == value: return
		_flip_normals = value
		request_update()

func _create_mesh_array() -> Array:
	var proportional_vector : Vector3 = Vector3(
		box_size.y / box_size.x if box_size.x > box_size.y else 1.0,
		box_size.x / box_size.y if box_size.y > box_size.x else 1.0,
		box_size.y / box_size.z if box_size.z > box_size.y else 1.0,
	) if proportional else Vector3.ONE

	var resolution_reciprocal := Vector2.ONE / Vector2(resolution)
	var super_power_reciprocal := 2.0 / super_power
	var normal_scalar := -1.0 if flip_normals else 1.0

	#region Vertices

	var vertices := PackedVector3Array()
	vertices.resize((resolution.x + 1) * (resolution.y + 1))
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	var uvs := PackedVector2Array()
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

			vertices[idx] = v
			normals[idx] = vertices[idx].normalized() * normal_scalar

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
		normals[idx] = vertices[idx].normalized() * normal_scalar
		uvs[idx] = Vector2(
			float(j) / float(resolution.y),
			1.0
		)

	#endregion
	#region Indeces

	var indeces := PackedInt32Array()
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

	#endregion

	var arrays := Array()
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indeces

	return arrays
