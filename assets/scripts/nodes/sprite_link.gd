
@tool
class_name SpriteLink extends Resource

enum TextureComponent {
	ALBEDO,
	EMISSIVE,
	ROM,
	NORMAL,
}


signal resource_changed_manually

var is_changing_internally : bool

var _sprite : Node2D
var sprite : Node2D :
	get: return _sprite
	set(value):
		if _sprite == value: return
		_sprite = value

		if sprite is Sprite2D:
			sprite.texture_changed.connect(resource_changed)

@export_storage var name : String
@export_storage var extension : String

var resource : Resource :
	get:
		if sprite is Sprite2D:
			return sprite.texture
		elif sprite is AnimatedSprite2D:
			return sprite.sprite_frames
		return null
	set(value):
		if sprite is Sprite2D:
			sprite.texture = value
		elif sprite is AnimatedSprite2D:
			sprite.sprite_frames = value


var _mirror : bool
@export_storage var mirror : bool :
	get: return _mirror
	set(value):
		_mirror = value

		refresh_resource_from_attributes()


var _component : TextureComponent
@export_storage var component : TextureComponent :
	get: return _component
	set(value):
		_component = value

		refresh_resource_from_attributes()

var path : String :
	get:
		var result := name

		match mirror:
			true:	result += "_l"
			false:	result += "_r"

		match component:
			TextureComponent.ALBEDO: 		result += "_a"
			TextureComponent.EMISSIVE: 		result += "_e"
			TextureComponent.ROM: 			result += "_m"
			TextureComponent.NORMAL: 		result += "_n"

		result += "." + extension
		return result

func populate(__sprite : Node2D) -> void:
	sprite = __sprite

	refresh_attributes_from_resource()


func _to_string() -> String:
	return "SpriteLink:" + name


func resource_changed() -> void:
	if is_changing_internally : return
	refresh_attributes_from_resource()
	resource_changed_manually.emit()


func refresh_resource_from_attributes() -> void:
	var _resource : Resource = null
	if OS.has_feature("template") or Utils.is_valid_path(path):
		_resource = load(path)
	if _resource == null:
		_mirror = not _mirror
		if OS.has_feature("template") or Utils.is_valid_path(path):
			_resource = load(path)

	is_changing_internally = true
	resource = _resource
	is_changing_internally = false


func refresh_attributes_from_resource() -> void:
	if resource == null:
		name = ""
		extension = ""
		mirror = false
		component = TextureComponent.ALBEDO
		return

	var _path : String = resource.resource_path

	var extension_regex := RegEx.create_from_string("\\.(\\w+)$")

	var extension_match := extension_regex.search(_path)
	extension = extension_match.get_string(1)
	name = _path.substr(0, extension_match.get_start())

	var mirror_regex := RegEx.create_from_string("_([lr])(?=[_.])")
	var mirror_match := mirror_regex.search(_path)
	if mirror_match:
		mirror = mirror_match.get_string(1) == "l"
		if mirror_match.get_start() < name.length():
			name = name.substr(0, mirror_match.get_start())
	else:
		mirror = false

	var component_regex := RegEx.create_from_string("_([aemno])(?=[_.])")
	var component_match := component_regex.search(_path)
	if component_match:
		match component_match.get_string(1):
			"a": component = TextureComponent.ALBEDO
			"e": component = TextureComponent.EMISSIVE
			"m": component = TextureComponent.ROM
			"n": component = TextureComponent.NORMAL
		if component_match.get_start() < name.length():
			name = name.substr(0, component_match.get_start())
	else:
		component = TextureComponent.ALBEDO
