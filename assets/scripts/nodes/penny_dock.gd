
@tool
class_name PennyDock extends Control

@export var message_log : RichTextLabel
@export var verbosity_selector : OptionButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	log_clear()


func log(s: String, c: Color = Penny.DEFAULT_COLOR) -> void:
	message_log.append_text("[color=#%s]%s[/color]\n" % [c.to_html(), s])


func log_clear() -> void:
	# print(message_log.text)
	message_log.text = String()
	message_log.append_text("[code]Penny VNE v0.0 (c) 2024-present Liam Wofford (@nulture)\n")
	# self.log("Cleared log.")


func _on_button_reload_pressed() -> void:
	PennyImporter.inst.reload(true)


func _on_link_clicked(meta) -> void:
	FileAddress.from_string(meta).open()


