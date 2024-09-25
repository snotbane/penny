
class_name PennyMessageLabel extends RichTextLabel

var record : Record
var handler : HistoryHandler

func _init(__record: Record) -> void:
	record = __record

	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	focus_mode = FOCUS_ALL
	visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING

	if not record.statement.is_record_user_facing:
		var c = get_theme_color('default_color')
		c.a = 0.25
		add_theme_color_override('default_color', c)
	pass

func refresh_visibility(verbosity: int) -> void:
	visible = record.verbosity >= 0 && verbosity >= record.verbosity

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_accept'):
		print("Accepted %s" % record)
		if record.host == null: return
		record.host.rewind_to(record)
	if event.is_action_pressed('ui_cancel'):
		release_focus()

