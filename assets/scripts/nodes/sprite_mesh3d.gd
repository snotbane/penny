
@tool
extends MeshInstance3D

@export var refresh : bool :
	get: return false
	set(value):
		_ready()
		_refresh_viewports()

var _template : SpriteComponentTemplate
@export var template : SpriteComponentTemplate :
	get: return _template
	set(value):
		if _template == value: return
		_template = value

		refresh_quad_size()

@export_subgroup("Sprite")

var _enable_mirrors : bool = true
@export var enable_mirrors : bool = true :
	get: return _enable_mirrors
	set(value):
		if _enable_mirrors == value: return
		_enable_mirrors = value

		if self.mat is ShaderMaterial:
			self.mat.set_shader_parameter(&"unique_backface", _enable_mirrors)

@export_flags("Emissive", "ROM", "Normal") var enable_components : int = 7
@export var opacity_source_component : SpriteComponent.TextureComponent

@export_subgroup("Mesh")

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
		if Engine.is_editor_hint(): return
		self.transparency = 1.0 - value
		if self.mat is ShaderMaterial:
			self.mat.set_shader_parameter('opacity', value)
		if value < 1.0:
			self.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			self.cast_shadow = self.cast_shadow


@onready var viewport : SubViewport = template.get_parent() if template else null


var quad : QuadMesh :
	get: return self.mesh

var mat : Material :
	get: return self.mesh.surface_get_material(0)


func _ready() -> void:
	if not self.mesh:
		self.mesh = QuadMesh.new()
	self.mesh.resource_local_to_scene = true
	refresh_quad_size()
	if not mat:	refresh_mat()


func refresh_mat() -> void:
	self.mesh.surface_set_material(0, ShaderMaterial.new())
	mat.resource_local_to_scene = true
	mat.shader = preload("res://addons/penny_godot/assets/shaders/sprite_3d.tres")



func refresh_quad_size() -> void:
	if not viewport or self.mesh is not QuadMesh: return
	quad.size = template.size * _pixel_size
	viewport.size = template.size


func _refresh_viewports() -> void:
	if not viewport: return
	for child in self.get_children():
		if child == viewport: continue
		self.remove_child(child)
		child.queue_free()

	viewport.size = template.size

	if self.mat is ShaderMaterial:
		var vptexture := ViewportTexture.new()
		vptexture.viewport_path = get_tree().edited_scene_root.get_path_to(viewport)
		self.mat.set_shader_parameter(&"unique_backface", _enable_mirrors)
		self.mat.set_shader_parameter("r_a", vptexture)

	if enable_mirrors:
		create_subviewport_from_template(true, SpriteComponent.TextureComponent.ALBEDO)
	else:
		remove_subviewport_from_template(true, SpriteComponent.TextureComponent.ALBEDO)

	for i in 3:
		var i1 := i + 1
		if not enable_components & (2 ** i):
			remove_subviewport_from_template(false, i1)
			remove_subviewport_from_template(true, i1)
			continue
		create_subviewport_from_template(false, i1)
		if not enable_mirrors:
			remove_subviewport_from_template(true, i1)
			continue
		create_subviewport_from_template(true, i1)


static func get_suffix(mirrored: bool, component : SpriteComponent.TextureComponent) -> String:
	var result := "_l" if mirrored else "_r"
	match component:
		SpriteComponent.TextureComponent.ALBEDO: 	result += "_a"
		SpriteComponent.TextureComponent.EMISSIVE: 	result += "_e"
		SpriteComponent.TextureComponent.ROM: 		result += "_m"
		SpriteComponent.TextureComponent.NORMAL: 	result += "_n"
	return result



func remove_subviewport_from_template(mirrored: bool, component : SpriteComponent.TextureComponent) -> void:
	var suffix := get_suffix(mirrored, component)

	if self.mat is ShaderMaterial:
		self.mat.set_shader_parameter(suffix.substr(1), null)


func create_subviewport_from_template(mirrored : bool, component : SpriteComponent.TextureComponent) -> SubViewport:
	var suffix := get_suffix(mirrored, component)

	var result : SubViewport = viewport.duplicate()
	while result.get_child_count() > 0:
		result.remove_child(result.get_child(0))
	self.add_child(result)
	result.owner = get_tree().edited_scene_root
	result.name = "_" + viewport.name.substr(0, viewport.name.length() - suffix.length()) + suffix

	if self.mat is ShaderMaterial:
		var vptexture := ViewportTexture.new()
		vptexture.viewport_path = get_tree().edited_scene_root.get_path_to(result)
		self.mat.set_shader_parameter(suffix.substr(1), vptexture)

	var comp := SpriteComponent.new()
	comp.template = template
	comp.mirrored = mirrored
	comp.component = component
	result.add_child(comp)
	comp.owner = get_tree().edited_scene_root
	comp.name = "_" + template.name + suffix

	result.set_display_folded(true)

	return result
