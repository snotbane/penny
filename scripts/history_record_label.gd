
class_name HistoryRecordLabel extends RichTextLabel

var record : Penny.Record

func _init(__record: Penny.Record, __verbosity: int = 0) -> void:
	record = __record

	fit_content = true
	text = record.text
	refresh_visibility(__verbosity)

	if not record.statement.is_record_user_facing:
		var c = get_theme_color('default_color')
		c.a = 0.25
		add_theme_color_override('default_color', c)
	pass

func refresh_visibility(verbosity: int) -> void:
	visible = record.verbosity >= 0 && verbosity >= record.verbosity

