## Default implementation of a dialog handler.
extends Control

@onready
var button : Button = $button

@onready
var label : RichTextLabel = $rich_text_label


func handle(record: Penny.Record):
	var message = record.data.message
	var translation : StringName = &""
	var text: Variant

	if message is String:
		text = message
	elif message is Penny.Message:
		text = message.get_translation(translation)

	if text is String:
		label.text = text
	elif text is Penny.Text:
		text.push_to_rich_text_label(label)

	await button.pressed
