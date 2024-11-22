
@tool
extends Node3D


var _material : Material
@export var material : Material :
	get: return _material
	set(value):
		if _material == value: return
		_material = value

		if not mesh_instance: return

		self.quad.surface_set_material(0, _material)


var _sprite_switcher : SpriteSwitcher
@export var sprite_switcher : SpriteSwitcher :
	get: return _sprite_switcher
	set(value):
		if _sprite_switcher == value: return
		_sprite_switcher = value
		pixel_size = _pixel_size


var _pixel_size : float = 0.001
@export_range(0.0001, 128, 0.0001, "m") var pixel_size : float = 0.001 :
	get: return _pixel_size
	set(value):
		_pixel_size = value

		if not mesh_instance: return
		if sprite_switcher:
			quad.size = sprite_switcher.size * _pixel_size
		else:
			quad.size = Vector2.ONE


var quad : QuadMesh :
	get: return self.mesh_instance.mesh


var mesh_instance : MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = QuadMesh.new()
	mesh_instance.mesh.surface_set_material(0, material)
	self.add_child.call_deferred(mesh_instance)
	ready_deferred.call_deferred()


func ready_deferred() -> void:
	pixel_size = pixel_size
