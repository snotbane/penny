
class_name MessageReceiver extends Control

@export var rich_text_label : RichTextLabel

func receive(message: Penny.Message) -> void:
	rich_text_label.bbcode_enabled = true
	rich_text_label.scroll_following = true
	rich_text_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	rich_text_label.text = message.text

	# grab_focus.call_deferred()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_accept'):
		pass
