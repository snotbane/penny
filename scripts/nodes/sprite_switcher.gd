
@tool
class_name SpriteSwitcher extends CanvasGroup

enum TextureComponent {
	ALBEDO,
	NORMAL,
	OCCLUSION,
	EMISSIVE,
	RSM,
}


class SpriteResource:
	static var extension_regex := RegEx.create_from_string("\\.(\\w+)$")
	static var mirror_regex := RegEx.create_from_string("_([lr])(?=[_.])")
	static var component_regex := RegEx.create_from_string("_(rsm|[aeno])(?=[_.])")

	var name : String
	var extension : String
	var mirror : bool
	var component : TextureComponent

	var path : String :
		get:
			var result := name

			match mirror:
				true:	result += "_l"
				false:	result += "_r"

			match component:
				TextureComponent.ALBEDO: 		result += "_a"
				TextureComponent.NORMAL: 		result += "_n"
				TextureComponent.OCCLUSION: 	result += "_o"
				TextureComponent.EMISSIVE: 		result += "_e"
				TextureComponent.RSM: 			result += "_rsm"

			result += "." + extension
			return result

	func _init(_name : String, _extension : String, _mirror : bool, _component : TextureComponent) -> void:
		name = _name
		extension = _extension
		mirror = _mirror
		component = _component

	static func new_from_path(path : String) -> SpriteResource:
		var extension_match := extension_regex.search(path)
		var _extension := extension_match.get_string(1)
		var _name := path.substr(0, extension_match.get_start())

		var _mirror_match := mirror_regex.search(path)
		var _mirror : bool
		if _mirror_match:
			_mirror = _mirror_match.get_string(1) == "l"
			if _mirror_match.get_start() < _name.length():
				_name = _name.substr(0, _mirror_match.get_start())
		else:
			_mirror = false

		var _component_match := component_regex.search(path)
		var _component : TextureComponent
		if _component_match:
			match _component_match.get_string(1):
				"a": _component = TextureComponent.ALBEDO
				"e": _component = TextureComponent.EMISSIVE
				"n": _component = TextureComponent.NORMAL
				"o": _component = TextureComponent.OCCLUSION
				"rsm": _component = TextureComponent.RSM
			if _component_match.get_start() < _name.length():
				_name = _name.substr(0, _component_match.get_start())
		else:
			_component = TextureComponent.ALBEDO

		return SpriteResource.new(_name, _extension, _mirror, _component)


var _size : Vector2i
@export var size : Vector2i :
	get: return _size
	set(value):
		_size = value
		var parent := get_parent()
		if parent is SubViewport:
			parent.size = self.size

var _mirror : bool
@export var mirror : bool :
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
			path = match.get_string(1) + sub + match.get_string(2)
			if not Utils.is_valid_path(path):
				sprite.visible = false
				continue
			var res := load(path)
			if res:
				sprite.visible = true
				sprite.texture = res
			else:
				sprite.visible = false


var _component : TextureComponent
@export var component : TextureComponent :
	get: return _component
	set(value):
		if _component == value: return
		_component = value
		var component_regex := RegEx.create_from_string(component_pattern)
		for sprite in sub_sprites:
			if not sprite.texture: continue
			var path : String = sprite.texture.resource_path
			var sub : String
			match _component:
				TextureComponent.NORMAL: sub = "_n"
				TextureComponent.OCCLUSION: sub = "_ao"
				TextureComponent.EMISSIVE: sub = "_e"
				TextureComponent.RSM: sub = "_rsm"
				_: sub = ""
			var match : RegExMatch = component_regex.search(path)
			path = match.get_string(1) + sub + match.get_string(2)
			if not Utils.is_valid_path(path): continue
			var res := load(path)
			if res:
				sprite.visible = true
				sprite.texture = res
			else:
				sprite.visible = false

@export_subgroup("Regex Patterns")

@export var mirror_pattern := "(.+?)(?:_[lr])((?:\\W|_).+)"

@export var component_pattern := "(.+?)(?:_(?:ao|rsm|[en]))?(\\.png)"


var sub_sprites : Array[Sprite2D] :
	get:
		var result : Array[Sprite2D] = []
		for child in self.get_children():
			if child is Sprite2D:
				result.push_back(child)
		return result


func _init() -> void:
	# size = size
	pass


func get_sprite_base_name(sprite: Node2D) -> String:


	if sprite is Sprite2D:
		return String()
	if sprite is AnimatedSprite2D:
		return String()
	return String()
