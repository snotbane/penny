
class_name DialogNode extends Actor

const PREVENT_SKIP_DELAY_SECONDS := 0.125

static var focus_left : bool = false

@export var name_label : RichTextLabel
@export var text_label : RichTextLabel
@export var typewriter : Typewriter


var is_mouse_inside : bool
var is_preventing_skip : bool
var message : DisplayString


func _enter_tree() -> void:
	if self.has_signal("mouse_entered") and self.has_signal("mouse_exited"):
		self.mouse_entered.connect(self.set.bind("is_mouse_inside", true))
		self.mouse_exited.connect(self.set.bind("is_mouse_inside", false))


func _populate() -> void:
	host.on_try_advance.connect(try_advance)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			focus_left = true
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			self.set_deferred("focus_left", false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		self.try_advance()

func _gui_input(event: InputEvent) -> void:
	if self.is_mouse_inside and event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
		self.try_advance()


func receive(record: Record) -> void:
	name_label.text = record.data["who"].text_as_display_string.text
	typewriter.receive(record)


func prevent_skip() -> void:
	is_preventing_skip = true
	await self.get_tree().create_timer(PREVENT_SKIP_DELAY_SECONDS, false, false, true).timeout
	is_preventing_skip = false


func try_advance() -> void:
	if focus_left: return
	if not is_open: return
	if typewriter.is_working:
		typewriter.prod()
		return
	if is_preventing_skip: return
	self.advanced.emit()
