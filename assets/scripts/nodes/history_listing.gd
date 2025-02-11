
class_name HistoryListing extends Control

@export var message_label : RichTextLabel

var record : Record

func populate(_record: Record) -> void:
	record = _record
	if not record.stmt.verbosity & Stmt.Verbosity.USER_FACING:
		var c = message_label.get_theme_color('default_color')
		c.a = 0.25
		message_label.add_theme_color_override('default_color', c)
	message_label.text = record.stmt.get_record_message(_record)
	_populate()
func _populate() -> void: pass


func refresh_visibility(verbosity: int) -> void:
	self.visible = verbosity & record.stmt.verbosity
