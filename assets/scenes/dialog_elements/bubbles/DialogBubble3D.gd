@tool
extends Node3D
class_name DialogBubble3D

@export_tool_button("Refresh") var refresh_button_ := refresh

@export var size_curve_x : Curve
@export var size_curve_y : Curve
@export var padding_curve_x : Curve
@export var padding_curve_y : Curve

@export_range(2, 2048) var viewport_pixels_per_unit : int = 100

@export_category("Family")

@export var offset : Node3D
@export var superegg : SupereggMeshInstance3D
@export var text_mesh : MeshInstance3D
@export var viewport : SubViewport
@export var padding_container : MarginContainer
@export var typewriter : Typewriter

@export_multiline var control_text : String :
	get: return typewriter.rtl.text
	set(value):
		if not typewriter: return
		typewriter.rtl.text = value

func _ready() -> void:
	clone_material()


func clone_material() -> void:
	text_mesh.mesh.surface_set_material(0, text_mesh.mesh.surface_get_material(0).duplicate())
	(text_mesh.mesh.surface_get_material(0) as StandardMaterial3D).albedo_texture = viewport.get_texture()
	# (text_mesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter(&"albedo_texture", viewport.get_texture())


func receive(record: Record) :
	await typewriter.receive(record)
	refresh()


func refresh() -> void:
	var total_characters := typewriter.rtl.get_total_character_count()
	var size := Vector2(
		size_curve_x.sample_baked(total_characters),
		size_curve_y.sample_baked(total_characters)
	)

	# var total_lines := typewriter.rtl.get_visible_line_count()
	# var padding := Vector2(
	# 	padding_curve_x.sample_baked(total_lines),
	# 	padding_curve_y.sample_baked(total_lines)
	# )
	var padding := Vector2.ONE * 0.1

	superegg.size.x = size.x + padding.x
	superegg.size.y = size.y + padding.y
	text_mesh.mesh.size = size + padding

	offset.position.y = superegg.size.y * 0.5

	viewport.size = text_mesh.mesh.size * viewport_pixels_per_unit

	var margin_override : Vector2i = floor(padding * float(viewport_pixels_per_unit) * 0.5)
	padding_container.add_theme_constant_override(&"margin_left", margin_override.x)
	padding_container.add_theme_constant_override(&"margin_right", margin_override.x)
	padding_container.add_theme_constant_override(&"margin_top", margin_override.y)
	padding_container.add_theme_constant_override(&"margin_bottom", margin_override.y)
