extends HistoryListing

@export var name_label : RichTextLabel

func _populate(_record: Record) -> void:
	name_label.text = str(_record.attachment.who)
	# name_label.visible = not _record.attachment.who.text.is_empty()
	message_label.text = str(_record.attachment.what)
