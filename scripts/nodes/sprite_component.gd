
@tool
class_name SpriteComponent extends Node2D


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


var dict : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_animated_sprite_current_texture(sprite: AnimatedSprite2D) -> Texture2D:
	return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)


func create_sprite_from_sprite_2d(sprite: Sprite2D) -> Sprite2D:
	var result := sprite.duplicate()
	self.add_child(result)
	result.owner = self

	return result


func create_sprite_from_animated_sprite_2d(sprite: AnimatedSprite2D) -> MeshInstance2D:
	var texture := get_animated_sprite_current_texture(sprite)

	var result := MeshInstance2D.new()
	var mesh := QuadMesh.new()
	mesh.size = texture.get_size() * Vector2(1, -1)
	result.texture = texture
	result.mesh = mesh
	result.name = sprite.name
	self.add_child(result, false, INTERNAL_MODE_DISABLED)
	result.owner = self

	# var result := Sprite2D.new()
	# print(result)
	# result.name = sprite.name
	# result.position = sprite.position
	# result.texture = texture
	# self.add_child(result)
	# dict[result] = sprite

	return result


func refresh_sprites() -> void:
	for sprite in dict.keys():
		var ref : AnimatedSprite2D = dict[sprite]
		sprite.texture = get_animated_sprite_current_texture(ref)
		print(sprite.texture.resource_path)
