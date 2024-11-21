
@tool
class_name SpriteSwitcher extends CanvasGroup

enum TextureComponent {
	ALBEDO,
	NORMAL,
	EMISSIVE,
	RSM,
}

@export var size : Vector2

@export var mirror_pattern := "_([lr])_"
@export var mirror_replace := "_%s_"
@export var texture_pattern := "_([aen]|rsm)\\."
@export var texture_replace := "_%s."

var _mirror : bool = false
@export var mirror : bool = false :
	get: return _mirror
	set(value):
		if _mirror == value: return
		_mirror = value

		var regex := RegEx.create_from_string(mirror_pattern)

		for sprite in sub_sprites:
			if not sprite.texture: continue
			var path : String = sprite.texture.resource_path
			var sub : String
			if _mirror:
				sub = "l"
			else:
				sub = "r"
			path = regex.sub(path, mirror_replace % sub)
			var tex := load(path)
			if tex:
				sprite.texture = tex

var _component : TextureComponent
@export var component : TextureComponent :
	get: return _component
	set(value):
		if _component == value: return
		_component = value

		var regex := RegEx.create_from_string(texture_pattern)
		for sprite in sub_sprites:
			if not sprite.texture: continue
			var path : String = sprite.texture.resource_path
			var sub : String
			match _component:
				TextureComponent.ALBEDO: sub = "a"
				TextureComponent.NORMAL: sub = "n"
				TextureComponent.EMISSIVE: sub = "e"
				TextureComponent.RSM: sub = "rsm"
				_: sub = "a"
			path = regex.sub(path, texture_replace % sub)
			var tex := load(path)
			if tex:
				sprite.texture = tex

var sub_sprites : Array[Sprite2D] :
	get:
		var result : Array[Sprite2D] = []
		for child in self.get_children():
			if child is Sprite2D:
				result.push_back(child)
		return result

