
class_name MessageHandler extends Control

signal received

@export var rich_text_label : RichTextLabel
@export var skip_prevent_timer : Timer

var watcher := Watcher.new()

func _ready() -> void:
	pass

func receive(record: Record) -> void:
	rich_text_label.text = record.message.text
	received.emit()

func prevent_skip() -> void:
	if skip_prevent_timer.is_stopped():
		skip_prevent_timer.start()

## WATCHER METHODS

var working : bool :
	get:
		return watcher.working or not skip_prevent_timer.is_stopped()

func wrap_up_work() -> void:
	watcher.wrap_up_work()
