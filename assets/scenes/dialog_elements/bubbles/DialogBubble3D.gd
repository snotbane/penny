@tool
extends Node3D
class_name DialogBubble3D

@export_tool_button("Refresh") var refresh_button_ := refresh
@export_tool_button("Rebuild Viewport Cache") var rebuild_viewport_cache_ := rebuild_viewport_cache

## Determines how the bubble grows in size. Domain is the total number of characters in the text, range is the width.
@export var size_curve_x : Curve
## Determines how the bubble grows in size. Domain is the number of currently visible lines, range is the height.
@export var size_curve_y : Curve
## Determines minimum size and size added between the text and the edges of the bubble. Domain is the total number of characters in the text, range is x padding.
@export var padding_curve_x : Curve
## Determines minimum size and size added between the text and the edges of the bubble. Domain is number of currently visible lines, range is y padding.
@export var padding_curve_y : Curve

@export_range(2, 2048) var viewport_pixels_per_unit : int = 100

#region Static Viewport Data
@export_subgroup("Static")

static var viewport_cache : Texture2DArray :
	get: return RenderingServer.global_shader_parameter_get(&"bubble_cache")
	set(value):
		RenderingServer.global_shader_parameter_set(&"bubble_cache", value)

# static var _viewports_used : int

static var _max_viewport_size : int = 2048
@export var max_viewport_size : int = 2048 :
	get: return _max_viewport_size
	set(value):
		if _max_viewport_size == value: return
		_max_viewport_size = value
		rebuild_viewport_cache()

static var _max_bubbles : int = 8
@export_range(0, 63) var max_bubbles : int = 8 :
	get: return _max_bubbles
	set(value):
		if _max_bubbles == value: return
		_max_bubbles = value
		rebuild_viewport_cache()

static func create_viewport_cache_layer() -> Image:
	return Image.create_empty(_max_viewport_size, _max_viewport_size, false, Image.FORMAT_RGBA8)

static func rebuild_viewport_cache() -> void:
	var images : Array[Image] = []
	images.resize(_max_bubbles)
	for i in _max_bubbles:
		images[i] = create_viewport_cache_layer()
	viewport_cache = Texture2DArray.new()
	viewport_cache.create_from_images(images)

var _bubble_id : int = 0
@export var bubble_id : int = 0 :
	get: return _bubble_id
	set(value):
		value = clampi(value, 0, _max_bubbles - 1)
		if _bubble_id == value: return
		_bubble_id = value
		text_mesh.set_instance_shader_parameter(&"bubble_id", _bubble_id)

static func request_new_bubble_id() -> int:
	return -1

#endregion

@export_category("Family")

@export var offset : Node3D
@export var superegg : SupereggMeshInstance3D
@export var text_mesh : MeshInstance3D
@export var viewport : SubViewport
@export var padding_container : MarginContainer
@export var typewriter : Typewriter

@export var control_text : String :
	get: return typewriter.rtl.text
	set(value):
		if not typewriter: return
		typewriter.rtl.text = value


# func _ready() -> void:

# 	refresh.call_deferred()

static func _static_init() -> void:
	rebuild_viewport_cache()
	# if not _viewport_cache: rebuild_viewport_cache()


func _process(delta: float) -> void:
	var viewport_image := viewport.get_texture().get_image()
	var image := viewport_cache.get_layer_data(bubble_id)
	image.blit_rect(viewport_image, Rect2i(Vector2i.ZERO, viewport_image.get_size()), Vector2i.ZERO)
	viewport_cache.update_layer(image, bubble_id)


func refresh() -> void:
	var total_characters := typewriter.rtl.get_total_character_count()
	var total_lines := typewriter.rtl.get_visible_line_count()

	# var padding := Vector2(
	# 	padding_curve_x.sample_baked(total_characters),
	# 	padding_curve_y.sample_baked(total_lines)
	# )
	var padding := Vector2.ONE * padding_curve_x.sample_baked(total_characters)

	var size := Vector2(
		size_curve_x.sample_baked(total_characters),
		size_curve_y.sample_baked(total_lines)
	)

	superegg.size.x = size.x + padding.x
	superegg.size.y = size.y + padding.y
	text_mesh.mesh.size = size + padding

	offset.position.y = superegg.size.y * 0.5

	viewport.size = text_mesh.mesh.size * viewport_pixels_per_unit
	text_mesh.set_instance_shader_parameter(&"viewport_ratio", Vector2(viewport.size) / float(_max_viewport_size))

	var margin_override : Vector2i = floor(padding * float(viewport_pixels_per_unit) * 0.5)
	padding_container.add_theme_constant_override(&"margin_left", margin_override.x)
	padding_container.add_theme_constant_override(&"margin_right", margin_override.x)
	padding_container.add_theme_constant_override(&"margin_top", margin_override.y)
	padding_container.add_theme_constant_override(&"margin_bottom", margin_override.y)
