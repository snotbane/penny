
class_name HistoryListing extends Control

@export var message_label : RichTextLabel

var record : Record

func populate(_record: Record) -> void:
	record = _record
	if not record.stmt.verbosity & Stmt.Verbosity.USER_FACING:
		var c = message_label.get_theme_color('default_color')
		c.a = 0.25
		message_label.add_theme_color_override('default_color', c)
	_populate(_record)
func _populate(_record: Record) -> void:
	message_label.text = record.stmt.get_record_message(_record)

func refresh_visibility(history: HistoryHandler) -> void:
	self.visible = history.verbosity & record.stmt.verbosity

