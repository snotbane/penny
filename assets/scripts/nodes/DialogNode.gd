## Actor suitable for receiving Dialog records and passing input to a [Typewriter].
class_name DialogNode extends Actor


static var focus_left : bool = false

## Defines a short period of time after the typewriter has finished typing in which input will be disabled. Used to help prevent users from accidentally skipping dialogue.
@export_range(0.0, 1.0, 0.01) var prevent_skip_duration : float = 0.1

var is_mouse_inside : bool
var is_preventing_skip : bool


var typewriter : Typewriter :
	get: return _get_typewriter()
func _get_typewriter() -> Typewriter:
	return null


func _enter_tree() -> void:
	if has_signal(&"mouse_entered") and has_signal(&"mouse_exited"):
		self.mouse_entered.connect(set.bind(&"is_mouse_inside", true))
		self.mouse_exited.connect(set.bind(&"is_mouse_inside", false))
	typewriter.advanced.connect(advanced.emit)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			focus_left = true
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			set_deferred(&"focus_left", false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(Penny.INPUT_ADVANCE):
		try_advance()
	if event.is_action_pressed(Penny.INPUT_ROLL_AHEAD):
		pass ## TODO: finish entire dialogue box


func _gui_input(event: InputEvent) -> void:
	if is_mouse_inside and event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
		try_advance()


func _populate() -> void:
	host.on_try_advance.connect(try_advance)


func receive(record: Record) :
	typewriter.receive(record)


func prevent_skip() -> void:
	if is_zero_approx(prevent_skip_duration): return

	is_preventing_skip = true
	await self.get_tree().create_timer(prevent_skip_duration, false, false, true).timeout
	is_preventing_skip = false


func try_advance() -> void:
	if focus_left: return
	if not is_entered: return
	if not typewriter: return
	if typewriter.is_working:
		typewriter.prod()
		return
	if is_preventing_skip: return
	advanced.emit()

