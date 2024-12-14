extends HistoryListing

@export var name_label : RichTextLabel

func _populate(_record: Record) -> void:
	name_label.text = str(_record.data["who"].rich_name.to_decorated())
	# name_label.visible = not _record.attachment.who.text.is_empty()
	message_label.text = str(_record.data["what"])
