
class_name MessageHandler extends PennyNode

const PREVENT_SKIP_DELAY_SECONDS := 0.125

signal received(message: DecoratedText)
signal advanced

static var focus_left : bool = false

@export var name_label : RichTextLabel
@export var text_label : RichTextLabel
@export var typewriter : Typewriter


var is_preventing_skip : bool
var message : DecoratedText


func _populate(_host: PennyHost, _object: PennyObject) -> void:
	_host.on_try_advance.connect(try_advance)
	advanced.connect(_host.advance)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			focus_left = true
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			self.set_deferred("focus_left", false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		try_advance()


func receive(record: Record, subject: PennyObject) -> void:
	name_label.text = str(record.attachment.who)
	received.emit(record.attachment.what)


func prevent_skip() -> void:
	is_preventing_skip = true
	await self.get_tree().create_timer(PREVENT_SKIP_DELAY_SECONDS, false, false, true).timeout
	is_preventing_skip = false


func try_advance() -> void:
	if focus_left: return

	if appear_state != AppearState.PRESENT: return
	if typewriter.is_working:
		typewriter.prod()
		return
	if is_preventing_skip: return
	advanced.emit()
