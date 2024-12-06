
@tool
class_name SpriteSwitcher extends CanvasGroup

@export var refresh: bool:
	set(value):
		# _ready()
		print(sprites)
@export var clear: bool:
	set(value):
		# _ready()
		sprites.clear()
		_ready()


var _size : Vector2i
@export var size : Vector2i :
	get: return _size
	set(value):
		_size = value
		if get_parent() is SubViewport:
			get_parent().size = self.size


var _mirror : bool
@export var mirror : bool :
	get: return _mirror
	set(value):
		if _mirror == value: return
		_mirror = value
		for k in sprites.keys():
			sprites[k].mirror = _mirror


var _component : SpriteLink.TextureComponent
@export var component : SpriteLink.TextureComponent :
	get: return _component
	set(value):
		if _component == value: return
		_component = value
		for k in sprites.keys():
			sprites[k].component = _component


@export_storage var sprites : Dictionary = {}


# func _init() -> void:
# 	init_deferred.call_deferred()


func init_deferred() -> void:
	size = size

	for child in self.get_children():
		if sprites.has(child.name):
			sprites[child.name].sprite = child
			sprites[child.name].refresh_resource_from_attributes()
			continue
		sprites[child.name] = SpriteLink.new()
		sprites[child.name].populate(child)
