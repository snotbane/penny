
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

		for child in self.get_children():
			child.queue_free()
		dict.clear()

		if _template == null: return

		position = _template.position

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
	if texture == null: return
	mesh.texture = get_modified_version(texture)
	mesh.visible = mesh.texture != null


class ResourceFallback:
	var folder : String
	var name : String
	var ext : String
	var index : int
	var mirror : bool
	var component : TextureComponent

	var build_path : String :
		get:
			var result := name

			if index >= 0:
				result += "_" + str(index).lpad(2, "0")

			match mirror:
				true:	result += "_l"
				_:		result += "_r"

			match component:
				TextureComponent.ALBEDO: 		result += "_a"
				TextureComponent.NORMAL: 		result += "_n"
				TextureComponent.OCCLUSION: 	result += "_o"
				TextureComponent.EMISSIVE: 		result += "_e"
				TextureComponent.RSM: 			result += "_m"

			return folder + result + ext

	var resource : Resource :
		get:
			var result := Utils.safe_load(build_path)
			if result: return result

			if mirror:
				mirror = false
				result = Utils.safe_load(build_path)
				if result: return result

			if index > 0:
				index = 0
				result = Utils.safe_load(build_path)
				if result: return result
			if index == 0:
				index = -1
				result = Utils.safe_load(build_path)
				if result: return result

			return null


	func _init(_resource : Resource, _mirror : bool, _component : TextureComponent) -> void:
		var path := _resource.resource_path
		folder = path.substr(0, path.rfind("/") + 1)
		path = path.substr(folder.length())

		var ext_regex := RegEx.create_from_string("\\.\\w+$")
		var ext_match := ext_regex.search(path)
		ext = ext_match.get_string()

		var name_length := ext_match.get_start()

		var index_regex := RegEx.create_from_string("_(\\d{2})(?=[_.])")
		var index_match := index_regex.search(path)
		if index_match:
			index = int(index_match.get_string(1))
			name_length = min(name_length, index_match.get_start())
		else:
			index = -1

		mirror = _mirror
		var mirror_regex := RegEx.create_from_string("_([lr])(?=[_.])")
		var mirror_match := mirror_regex.search(path)
		if mirror_match:
			name_length = min(name_length, mirror_match.get_start())

		component = _component
		var component_regex := RegEx.create_from_string("_([aemno])(?=[_.])")
		var component_match := component_regex.search(path)
		if component_match:
			name_length = min(name_length, component_match.get_start())

		name = path.substr(0, name_length)


func get_modified_version(resource: Resource) -> Resource:
	var fallback := ResourceFallback.new(resource, mirror, component)
	return fallback.resource


func refresh_mesh_from_sprite_2d(mesh: MeshInstance2D) -> void:
	set_mesh_texture(mesh, dict[mesh].texture)


func refresh_mesh_from_animated_sprite_2d(mesh: MeshInstance2D) -> void:
	set_mesh_texture(mesh, get_animated_sprite_current_texture(dict[mesh]))
