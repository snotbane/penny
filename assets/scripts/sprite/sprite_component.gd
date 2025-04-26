
@tool
class_name SpriteComponent extends Node2D

const COMPOSITE_SPRITE2D_SCRIPT := preload("res://addons/fatlas/assets/scripts/composite_sprite2d.gd")

enum TextureComponent {
	ALBEDO,
	EMISSIVE,
	ROM,
	NORMAL,
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
		sprite_nodes.clear()

		if _template == null: return

		position = _template.position
		create_sprites_from_node(_template)
		refresh_all()


func create_sprites_from_node(node: Node2D) -> void:
	for child in node.get_children():
		if child is AnimatedSprite2D:
			create_sprite_from_animated_sprite_2d(child)
		elif child is Sprite2D:
			create_sprite_from_sprite_2d(child)
		elif child is Node2D:
			create_sprites_from_node(child)


var _mirrored : bool
##
@export var mirrored : bool :
	get: return _mirrored
	set(value):
		if _mirrored == value: return
		_mirrored = value
		for mesh in sprite_nodes.keys():
			mesh.mirrored = _mirrored
		# refresh_all()


var _component : TextureComponent
##
@export var component : TextureComponent :
	get: return _component
	set(value):
		if _component == value: return
		_component = value
		for mesh in sprite_nodes.keys():
			mesh.component = _component
		# refresh_all()


var sprite_nodes : Dictionary

func refresh_all() -> void:
	for mesh in sprite_nodes.keys():
		mesh.mirrored = mirrored
		mesh.component = component


func get_animated_sprite_current_texture(sprite: AnimatedSprite2D) -> Texture2D:
	return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)


func create_mesh(node: Node2D, texture: Texture2D) -> Sprite2D:
	var result := Sprite2D.new()

	result.set_script(COMPOSITE_SPRITE2D_SCRIPT)
	result.texture = texture
	result.centered = node.centered
	result.name = node.name
	set_texture(result, texture)

	self.sprite_nodes[result] = node
	self.add_child(result, false, INTERNAL_MODE_DISABLED)

	return result


func create_sprite_from_sprite_2d(sprite: Sprite2D) -> Sprite2D:
	var result := create_mesh(sprite, sprite.texture)
	sprite.texture_changed.connect(refresh_sprite2d.bind(result))
	return result


func create_sprite_from_animated_sprite_2d(sprite: AnimatedSprite2D) -> Sprite2D:
	var result := create_mesh(sprite, get_animated_sprite_current_texture(sprite))
	sprite.sprite_frames_changed.connect(refresh_animated_sprite2d.bind(result))
	sprite.animation_changed.connect(refresh_animated_sprite2d.bind(result))
	sprite.frame_changed.connect(refresh_animated_sprite2d.bind(result))
	return result


func set_texture(node: Node2D, texture: Texture2D) -> void:
	node.texture = texture
	node.visible = node.texture != null


func refresh_sprite2d(node: Sprite2D) -> void:
	set_texture(node, sprite_nodes[node].texture)


func refresh_animated_sprite2d(node: Sprite2D) -> void:
	set_texture(node, get_animated_sprite_current_texture(sprite_nodes[node]))
