
class_name MessageHandler extends PennyNode

signal received(message: Message)
signal advanced

@export var name_label : RichTextLabel
@export var text_label : RichTextLabel
@export var typewriter : Typewriter
@export var skip_prevent_timer : Timer


var message : Message


func _populate(_host: PennyHost, _object: PennyObject) -> void:
	advanced.connect(_host.advance)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_advance'):
		try_advance()


func _gui_input(event: InputEvent) -> void:
	pass
		# try_advance()


func receive(record: Record, subject: PennyObject) -> void:
	name_label.text = subject.rich_name
	received.emit(record.attachment)


func prevent_skip() -> void:
	if skip_prevent_timer.is_stopped():
		skip_prevent_timer.start()


func try_advance() -> void:
	if appear_state != AppearState.PRESENT: return
	if typewriter.working:
		typewriter.prod_work()
		return
	if not skip_prevent_timer.is_stopped():	return
	advanced.emit()
