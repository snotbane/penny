@tool class_name ViewAngleScaler extends Node3D

@export var z_distance := 0.01
@export var affect_scale_x := true
# @export var affect_scale_y := true
@export var affect_scale_z := true

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		## Commenting this out because EditorInterface does not work in packaged builds, best to not touch it.
		## Some preprocessor directives sure would be nice here.
		# self.scale.z = EditorInterface.get_editor_viewport_3d().get_camera_3d().global_basis.z.dot(get_parent().global_basis.z)
		return
	else:
		self.scale.z = self.get_viewport().get_camera_3d().global_basis.z.dot(get_parent().global_basis.z)
	self.scale.x = self.scale.z
	# self.scale.x = signf(self.scale.z)
	self.position.z = self.scale.z * z_distance
