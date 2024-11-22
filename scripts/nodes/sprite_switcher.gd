
@tool
class_name SpriteSwitcher extends CanvasGroup

enum TextureComponent {
	ALBEDO,
	NORMAL,
	EMISSIVE,
	RSM,
}

var _size : Vector2
@export var size : Vector2 :
	get: return _size
	set(value):
		_size = value
		var parent := get_parent()
		if parent is SubViewport:
			parent.size = self.size

@export var mirror_pattern := "(.+?)(_[lr])((?:\\W|_).+)"
@export var mirror_replace := "_%s_"
@export var texture_pattern := "(.+?)(_(?:rsm|[en]))?(\\.png)"
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
				sub = "_l"
			else:
				sub = "_r"
			var match : RegExMatch = regex.search(path)
			path = match.get_string(1) + sub + match.get_string(3)
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
				TextureComponent.NORMAL: sub = "_n"
				TextureComponent.EMISSIVE: sub = "_e"
				TextureComponent.RSM: sub = "_rsm"
				_: sub = ""
			var match : RegExMatch = regex.search(path)
			var tex := load(match.get_string(1) + sub + match.get_string(3))
			if tex:
				sprite.texture = tex

var sub_sprites : Array[Sprite2D] :
	get:
		var result : Array[Sprite2D] = []
		for child in self.get_children():
			if child is Sprite2D:
				result.push_back(child)
		return result


func _ready() -> void:
	size = size
