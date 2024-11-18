extends HistoryListing

@export var name_label : RichTextLabel

func _populate(_record: Record) -> void:
	name_label.text = str(_record.attachment.who)
	message_label.text = str(_record.attachment.what)
