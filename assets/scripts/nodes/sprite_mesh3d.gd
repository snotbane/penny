
@tool
extends MeshInstance3D

@export var refresh_all : bool :
	get: return false
	set(value):
		refresh_quad_size()

@export var template_svp : SubViewport

var _template : SpriteComponentTemplate
@export var template : SpriteComponentTemplate :
	get: return _template
	set(value):
		if _template == value: return
		_template = value

		refresh_quad_size()

var _pixel_size : float = 0.001
@export_range(0.0001, 1.0, 0.0001, "or_greater") var pixel_size : float = 0.001 :
	get: return _pixel_size
	set(value):
		if _pixel_size == value: return
		_pixel_size = value

		refresh_quad_size()


@export_range(0, 1, 0.001) var opacity : float = 1.0 :
	get: return 1.0 - self.transparency
	set(value):
		self.transparency = 1.0 - value
		if self.material is ShaderMaterial:
			self.material.set_shader_parameter('opacity', value)
		if value < 1.0:
			self.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			self.cast_shadow = self.cast_shadow


@export var opacity_source_component : SpriteComponent.TextureComponent


var quad : QuadMesh :
	get: return self.mesh

var mat : ShaderMaterial :
	get: return self.mesh.surface_get_material(0)


func _ready() -> void:
	refresh_quad_size()
	if not mat:
		self.mesh.surface_set_material(0, ShaderMaterial.new())
		mat.resource_local_to_scene = true
		mat.shader = preload("res://addons/penny_godot/assets/shaders/sprite_3d.tres")


func refresh_quad_size() -> void:
	if self.mesh is not QuadMesh: return
	quad.size = template.size * _pixel_size
	template_svp.size = template.size
