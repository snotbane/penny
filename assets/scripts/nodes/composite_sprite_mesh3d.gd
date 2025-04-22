@tool extends CompositeVisualInstance3D

@export_range(0, 1, 0.001) var opacity : float = 1.0 :
	get: return 1.0 - self.transparency
	set(value):
		# if Engine.is_editor_hint(): return
		self.transparency = 1.0 - value
		if self.material is ShaderMaterial:
			var this = self
			this.set_instance_shader_parameter(&"opacity", value)
		if value < 1.0:
			self.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			self.cast_shadow = self.cast_shadow


func refresh() -> void:
	super.refresh()
	self.mesh = self.quad
