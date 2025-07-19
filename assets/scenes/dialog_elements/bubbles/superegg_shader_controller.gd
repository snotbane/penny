@tool
extends MeshInstance3D

@export var size := Vector3(2, 1, 1)
@export var super_power := 2.5

var superegg : SphereMesh :
	get: return mesh

var material : ShaderMaterial :
	get: return mesh.surface_get_material(0)

func _ready() -> void:
	if Engine.is_editor_hint(): return

	superegg = superegg.duplicate()

func _process(delta: float) -> void:
	set_instance_shader_parameter(&"superegg_size", size)
	set_instance_shader_parameter(&"superegg_power", super_power)

	if Engine.is_editor_hint(): return

	superegg.custom_aabb.size = size;
