
class_name MessageHandler extends Control

signal received

@export var rich_text_label : RichTextLabel

func _ready() -> void:
	pass

func receive(message: Message) -> void:
	rich_text_label.text = message.text
	received.emit()
