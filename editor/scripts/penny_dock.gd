
@tool
class_name PennyDock extends Control

static var inst : PennyDock

@export var message_box : VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	inst = self
	log_clear()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func log(s: String, c: Color = Penny.DEFAULT_COLOR) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.context_menu_enabled = true
	label.selection_enabled = true
	label.focus_mode = Control.FOCUS_NONE
	match c:
		Penny.ERROR_COLOR, Penny.WARNING_COLOR:
			label.text = "\u2B24 %s" % s
		_:
			label.text = s
	label.add_theme_color_override('default_color', c)
	label.meta_clicked.connect(_on_link_clicked)
	message_box.add_child.call_deferred(label)

func log_clear() -> void:
	for i in message_box.get_children():
		message_box.remove_child(i)

func _on_button_reload_pressed() -> void:
	PennyImporter.inst.reload(true)

func _on_link_clicked(meta) -> void:
	FileAddress.from_string(meta).open()


