## Default implementation of a dialog handler.
extends Control

@onready
var button : Button = $button

@onready
var label : RichTextLabel = $rich_text_label


func handle(record: Penny.Record):
	var translation : StringName = &""
	var text = record.data.message.get_translation(translation)

	if text is String:
		label.text = text
	elif text is Penny.Text:
		text.push_to_rich_text_label(label)

	await button.pressed
