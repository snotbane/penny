extends ScrollContainer

@export var autoscroll_speed : float = 10.0

@export var minimum_size : Vector2
@export var maximum_size : Vector2
@export var add_size : Vector2

@export var driver : Control
func set_driver(control: Control) -> void:
	driver = control

var v_scroll_bar : VScrollBar

var manual_override : bool
var last_scroll_value : float

func _ready() -> void:
	v_scroll_bar = get_v_scroll_bar()
	custom_minimum_size = minimum_size


func _process(delta: float) -> void:
	if not driver: return

	var driven_size := driver.size

	var target_size := Vector2(
		custom_minimum_size.x,
		driven_size.y + add_size.y
	)
	target_size = target_size.max(minimum_size)
	if maximum_size != Vector2.ZERO:
		target_size = target_size.min(maximum_size)

	var maximum_size_y_reached := target_size.y == maximum_size.y
	var max_scroll_y := (driver.size.y - size.y) + (add_size.y / (1.0 if maximum_size_y_reached else 2.0))

	manual_override = v_scroll_bar.value < (max_scroll_y if manual_override else last_scroll_value) and maximum_size_y_reached

	if not manual_override:
		## custom_minimum_size is never changed after maximum_size_y_reached
		custom_minimum_size = lerp(
			custom_minimum_size,
			target_size,
			autoscroll_speed * delta
		)
		v_scroll_bar.value = lerp(
			v_scroll_bar.value,
			max_scroll_y,
			(autoscroll_speed * delta) if maximum_size_y_reached else 1.0
		)
		last_scroll_value = v_scroll_bar.value
