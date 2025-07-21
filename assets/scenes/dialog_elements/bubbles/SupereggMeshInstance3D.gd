@tool
extends MeshInstance3D
class_name SupereggMeshInstance3D

var _size := Vector3.ONE
@export var size := Vector3.ONE :
	get: return _size
	set(value):
		if _size == value: return
		_size = value
		superegg.custom_aabb.size = size
		set_instance_shader_parameter(&"superegg_size", size)

var _super_power : float = 2.5
@export var super_power : float = 2.5 :
	get: return _super_power
	set(value):
		if _super_power == value: return
		_super_power = value
		set_instance_shader_parameter(&"superegg_power", super_power)


var superegg : SphereMesh :
	get: return mesh

var material : ShaderMaterial :
	get: return mesh.surface_get_material(0)


func _ready() -> void:
	if Engine.is_editor_hint(): return

	superegg = superegg.duplicate()


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return

	superegg.custom_aabb.position = -global_position
