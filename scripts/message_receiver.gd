class_name MessageReceiver extends Container

@export var rich_text_label : RichTextLabel

func receive(message: Penny.Message) -> void:
	rich_text_label.text = message.text
	pass
