
@tool
extends MeshInstance3D

@export var refresh_all : bool :
	get: return false
	set(value): _ready()

@export_category("SubViewports")

@export var template_svp : SubViewport

var _template : SpriteComponentTemplate
@export var template : SpriteComponentTemplate :
	get: return _template
	set(value):
		if _template == value: return
		_template = value

		refresh_quad_size()

@export var refresh_viewports : bool :
	get: return false
	set(value):	_refresh_viewports()
@export var enable_mirrors : bool = true
@export_flags("Emissive", "ROM", "Normal") var enable_components : int = 7
@export var opacity_source_component : SpriteComponent.TextureComponent

@export_category("Mesh")

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


var quad : QuadMesh :
	get: return self.mesh

var mat : ShaderMaterial :
	get: return self.mesh.surface_get_material(0)


func _ready() -> void:
	if not self.mesh:
		self.mesh = QuadMesh.new()
	self.mesh.resource_local_to_scene = true
	refresh_quad_size()
	if not mat:
		self.mesh.surface_set_material(0, ShaderMaterial.new())
		mat.resource_local_to_scene = true
		mat.shader = preload("res://addons/penny_godot/assets/shaders/sprite_3d.tres")


func refresh_quad_size() -> void:
	if self.mesh is not QuadMesh: return
	quad.size = template.size * _pixel_size
	template_svp.size = template.size


func _refresh_viewports() -> void:
	for child in self.get_children():
		if child == template_svp: continue
		self.remove_child(child)
		child.queue_free()

	template_svp.size = template.size

	if enable_mirrors:
		create_subviewport_from_template(true, SpriteComponent.TextureComponent.ALBEDO)

	for i in 3:
		create_subviewport_from_template(false, i + 1)
		if not enable_mirrors: continue
		create_subviewport_from_template(true, i + 1)


func create_subviewport_from_template(mirrored : bool, component : SpriteComponent.TextureComponent) -> SubViewport:
	var suffix := "_l" if mirrored else "_r"
	match component:
		SpriteComponent.TextureComponent.ALBEDO: 	suffix += "_a"
		SpriteComponent.TextureComponent.EMISSIVE: 	suffix += "_e"
		SpriteComponent.TextureComponent.ROM: 		suffix += "_m"
		SpriteComponent.TextureComponent.NORMAL: 	suffix += "_n"

	var result : SubViewport = template_svp.duplicate()
	self.add_child(result)
	result.owner = get_tree().edited_scene_root
	result.name = "_" + template_svp.name + suffix


	var comp := SpriteComponent.new()
	comp.template = template
	comp.mirrored = mirrored
	comp.component = component
	result.add_child(comp)
	comp.owner = get_tree().edited_scene_root
	comp.name = "_" + template.name + suffix

	result.set_display_folded(true)

	return result


