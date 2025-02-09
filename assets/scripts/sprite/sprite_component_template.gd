
@tool
class_name SpriteComponentTemplate extends Node2D

enum PreviewLocation {
	ON_TOP,
	RIGHT,
	BOTTOM
}


var _size : Vector2i
##
@export var size : Vector2i :
	get: return _size
	set(value):
		if _size == value: return
		_size = value

		preview_location = preview_location


@export_subgroup("Preview")

var preview : SpriteComponent
@onready var _show_preview : bool = false
##
@export var show_preview : bool :
	get: return _show_preview
	set(value):
		if not Engine.is_editor_hint(): return
		if _show_preview == value: return
		_show_preview = value

		if preview:
			preview.queue_free()
			preview = null

		if _show_preview:
			preview = SpriteComponent.new()
			preview.name = "preview"
			self.add_child(preview, false, INTERNAL_MODE_BACK)
			self.set_deferred("preview_location", preview_location)
			preview.template = self
			preview.mirrored = _preview_mirror
			preview.component = _preview_component


var _preview_mirror : bool
##
@export var preview_mirror : bool :
	get: return _preview_mirror
	set(value):
		_preview_mirror = value
		if preview == null: return
		preview.mirrored = _preview_mirror


var _preview_component : SpriteComponent.TextureComponent
##
@export var preview_component : SpriteComponent.TextureComponent :
	get: return _preview_component
	set(value):
		_preview_component = value
		if preview == null: return
		preview.component = _preview_component


var _preview_location : PreviewLocation
##
@export var preview_location : PreviewLocation :
	get: return _preview_location
	set(value):
		_preview_location = value

		if preview == null : return

		match _preview_location:
			PreviewLocation.ON_TOP: preview.position = Vector2.ZERO
			PreviewLocation.RIGHT: preview.position =  Vector2.RIGHT * Vector2(self.size)
			PreviewLocation.BOTTOM: preview.position = Vector2.DOWN * Vector2(self.size)

