@tool
extends Node3D
class_name DialogBubble3D

## Determines how the bubble grows in size. Domain is the total number of characters in the text, range is the width.
@export var size_curve_x : Curve
## Determines how the bubble grows in size. Domain is the number of currently visible lines, range is the height.
@export var size_curve_y : Curve
## Determines minimum size and size added between the text and the edges of the bubble. Domain is the total number of characters in the text, range is x padding.
@export var padding_curve_x : Curve
## Determines minimum size and size added between the text and the edges of the bubble. Domain is number of currently visible lines, range is y padding.
@export var padding_curve_y : Curve

@export_range(2, 2048) var viewport_pixels_per_unit : int = 100

@export_category("Family")

@export var superegg : SupereggMeshInstance3D
@export var quad : MeshInstance3D
@export var viewport : SubViewport
@export var padding_container : MarginContainer
@export var typewriter : Typewriter


func _process(delta: float) -> void:
	var total_characters := typewriter.rtl.get_total_character_count()
	var total_lines := typewriter.rtl.get_visible_line_count()

	var padding := Vector2(
		padding_curve_x.sample_baked(total_characters),
		padding_curve_y.sample_baked(total_lines)
	)

	var size := Vector2(
		size_curve_x.sample_baked(total_characters),
		size_curve_y.sample_baked(total_lines)
	)

	superegg.size.x = size.x + padding.x
	superegg.size.y = size.y + padding.y
	quad.mesh.size = size + padding

	viewport.size = quad.mesh.size * viewport_pixels_per_unit

	var margin_override : Vector2i = floor(padding * float(viewport_pixels_per_unit) * 0.5)
	padding_container.add_theme_constant_override(&"margin_left", margin_override.x)
	padding_container.add_theme_constant_override(&"margin_right", margin_override.x)
	padding_container.add_theme_constant_override(&"margin_top", margin_override.y)
	padding_container.add_theme_constant_override(&"margin_bottom", margin_override.y)
