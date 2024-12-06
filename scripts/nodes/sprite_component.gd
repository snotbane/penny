
@tool
class_name SpriteComponent extends Node2D

enum TextureComponent {
	ALBEDO,
	NORMAL,
	OCCLUSION,
	EMISSIVE,
	RSM,
}

var _template : SpriteComponentTemplate
##
@export var template : SpriteComponentTemplate :
	get: return _template
	set(value):
		if _template == value: return
		_template = value
		if _template == null: return

		for child in self.get_children():
			child.queue_free()
		dict.clear()

		for child in _template.get_children():
			if child is AnimatedSprite2D:
				create_sprite_from_animated_sprite_2d(child)
			elif child is Sprite2D:
				create_sprite_from_sprite_2d(child)


var _mirror : bool
##
@export var mirror : bool :
	get: return _mirror
	set(value):
		if _mirror == value: return
		_mirror = value
		refresh_all()


var _component : TextureComponent
##
@export var component : TextureComponent :
	get: return _component
	set(value):
		if _component == value: return
		_component = value
		refresh_all()


var dict : Dictionary


func refresh_all() -> void:
	for mesh in dict.keys():
		var node : Node2D = dict[mesh]
		if node is Sprite2D:
			refresh_mesh_from_sprite_2d(mesh)
		elif node is AnimatedSprite2D:
			refresh_mesh_from_animated_sprite_2d(mesh)


func get_animated_sprite_current_texture(sprite: AnimatedSprite2D) -> Texture2D:
	return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)


func create_mesh(sprite: Node2D, texture: Texture2D) -> MeshInstance2D:
	var quad := QuadMesh.new()
	quad.size = texture.get_size() * Vector2(1, -1)

	var result := MeshInstance2D.new()

	result.mesh = quad
	result.name = sprite.name
	set_mesh_texture(result, texture)

	self.dict[result] = sprite
	self.add_child(result, false, INTERNAL_MODE_DISABLED)

	return result


func create_sprite_from_sprite_2d(sprite: Sprite2D) -> MeshInstance2D:
	var result := create_mesh(sprite, sprite.texture)
	sprite.texture_changed.connect(refresh_mesh_from_sprite_2d.bind(result))
	return result


func create_sprite_from_animated_sprite_2d(sprite: AnimatedSprite2D) -> MeshInstance2D:
	var result := create_mesh(sprite, get_animated_sprite_current_texture(sprite))
	sprite.animation_changed.connect(refresh_mesh_from_animated_sprite_2d.bind(result))
	sprite.frame_changed.connect(refresh_mesh_from_animated_sprite_2d.bind(result))
	return result


func set_mesh_texture(mesh: MeshInstance2D, texture: Texture2D) -> void:
	var path : String = get_altered_path(texture.resource_path)

	var resource : Resource = null
	if OS.has_feature("template") or Utils.is_valid_path(path):
		resource = load(path)

	if resource:
		mesh.texture = resource
		# mesh.visible = true
	# else:
		# mesh.visible = false


func get_altered_path(path : String) -> String:
	var result := path

	var extension_regex := RegEx.create_from_string("\\.(\\w+)$")
	var extension_match := extension_regex.search(path)
	var extension := extension_match.get_string(1)
	var mirror_regex := RegEx.create_from_string("_([lr])(?=[_.])")
	var mirror_match := mirror_regex.search(path)
	if mirror_match:
		if mirror_match.get_start() < result.length():
			result = result.substr(0, mirror_match.get_start())
	var component_regex := RegEx.create_from_string("_([aemno])(?=[_.])")
	var component_match := component_regex.search(path)
	if component_match.get_start() < result.length():
		result = result.substr(0, component_match.get_start())

	match mirror:
		true:	result += "_l"
		false:	result += "_r"
	match component:
		TextureComponent.ALBEDO: 		result += "_a"
		TextureComponent.NORMAL: 		result += "_n"
		TextureComponent.OCCLUSION: 	result += "_o"
		TextureComponent.EMISSIVE: 		result += "_e"
		TextureComponent.RSM: 			result += "_m"

	result += "." + extension
	return result


func refresh_mesh_from_sprite_2d(mesh: MeshInstance2D) -> void:
	set_mesh_texture(mesh, dict[mesh].texture)


func refresh_mesh_from_animated_sprite_2d(mesh: MeshInstance2D) -> void:
	set_mesh_texture(mesh, get_animated_sprite_current_texture(dict[mesh]))
