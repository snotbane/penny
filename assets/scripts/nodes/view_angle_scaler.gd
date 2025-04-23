@tool class_name ViewAngleScaler extends Node3D

@export var z_distance := 0.01
@export var affect_scale_x := true
# @export var affect_scale_y := true
@export var affect_scale_z := true

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		self.scale.z = EditorInterface.get_editor_viewport_3d().get_camera_3d().global_basis.z.dot(get_parent().global_basis.z)
	else:
		self.scale.z = self.get_viewport().get_camera_3d().global_basis.z.dot(get_parent().global_basis.z)
	self.scale.x = self.scale.z
	# self.scale.x = signf(self.scale.z)
	self.position.z = self.scale.z * z_distance
