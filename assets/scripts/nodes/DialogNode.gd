## Actor suitable for receiving Dialog records and passing input to a [Typewriter].
class_name DialogNode extends Actor

const PREVENT_SKIP_DELAY_SECONDS := 0.125

static var focus_left : bool = false


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


func _gui_input(event: InputEvent) -> void:
	if is_mouse_inside and event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
		try_advance()


func _populate() -> void:
	host.on_try_advance.connect(try_advance)


func receive(record: Record) :
	typewriter.receive(record)


func prevent_skip() -> void:
	is_preventing_skip = true
	await self.get_tree().create_timer(PREVENT_SKIP_DELAY_SECONDS, false, false, true).timeout
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

