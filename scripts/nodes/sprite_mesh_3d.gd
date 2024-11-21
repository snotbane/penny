
@tool
extends MeshInstance3D


@export var refresh : bool :
	set(value):
		var all_viewports := viewports
		for i in 2 - all_viewports.size():
			var viewport := SubViewport.new()
			viewport.transparent_bg = true
			self.add_child.call_deferred(viewport)
			all_viewports.push_back(viewport)
		for i in all_viewports.size():
			var viewport := all_viewports[i]
			var switcher : SpriteSwitcher
			if viewport.get_child(0) is SpriteSwitcher:
				switcher = viewport.get_child(0)
			else:
				switcher = sprite_switcher.duplicate()
				# switcher.owner = viewport
				viewport.add_child.call_deferred(switcher)
		refresh_deferred.call_deferred()


func refresh_deferred() -> void:
	var _viewports := viewports
	for i in _viewports.size():
		var viewport := _viewports[i]
		viewport.owner = self
		var switcher : SpriteSwitcher = viewport.get_child(0)
		var viewport_texture := ViewportTexture.new()
		viewport_texture.viewport_path = get_parent().get_path_to(viewport)
		var material_parameter : StringName
		match i:
			0:
				switcher.component = SpriteSwitcher.TextureComponent.ALBEDO
				material_parameter = "albedo"
			1:
				switcher.component = SpriteSwitcher.TextureComponent.NORMAL
				material_parameter = "normal"
		material.set_shader_parameter(material_parameter, viewport_texture)



var _material : ShaderMaterial
@export var material : ShaderMaterial :
	get: return _material
	set(value):
		if _material == value: return
		_material = value
		self.mesh.surface_set_material(0, _material)


var _sprite_switcher : SpriteSwitcher
@export var sprite_switcher : SpriteSwitcher :
	get: return _sprite_switcher
	set(value):
		if _sprite_switcher == value: return
		_sprite_switcher = value
		pixel_size = _pixel_size


var _pixel_size : float = 0.001
@export_range(0.0001, 128, 0.00001, "m") var pixel_size : float = 0.001 :
	get: return _pixel_size
	set(value):
		_pixel_size = value

		if not sprite_switcher: return

		quad.size = sprite_switcher.size * _pixel_size


var quad : QuadMesh :
	get: return self.mesh


var viewports : Array[SubViewport] :
	get:
		var result : Array[SubViewport] = []
		for child in self.get_children():
			if child is SubViewport:
				result.push_back(child)
		return result


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if self.mesh is not QuadMesh:
		self.mesh = QuadMesh.new()
	self.mesh = self.mesh.duplicate()
	self.mesh.surface_set_material(0, material)
