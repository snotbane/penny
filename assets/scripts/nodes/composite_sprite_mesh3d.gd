@tool extends CompositeVisualInstance3D


var _pixel_size : float = 0.001
@export_range(0.0001, 1.0, 0.0001, "or_greater") var pixel_size : float = 0.001 :
	get: return _pixel_size
	set(value):
		if _pixel_size == value: return
		_pixel_size = value
		refresh_quad()


@export_range(0, 1, 0.001) var opacity : float = 1.0 :
	get: return 1.0 - self.transparency
	set(value):
		# if Engine.is_editor_hint(): return
		self.transparency = 1.0 - value
		if self.material is ShaderMaterial:
			self.material.set_instance_shader_parameter(&"opacity", value)
		if value < 1.0:
			self.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			self.cast_shadow = self.cast_shadow


var quad : QuadMesh :
	get: return self.mesh


func refresh() -> void:
	super.refresh()
	refresh_quad()


func refresh_quad() -> void:
	if self.mesh is not QuadMesh:
		self.mesh = QuadMesh.new()
		self.mesh.resource_local_to_scene = true
	self.mesh.material = self.material
	quad.size = template.size * pixel_size


# func refresh_material() -> void:
# 	super.refresh_material()

