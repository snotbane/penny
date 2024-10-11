
@tool
class_name PennyDock extends Control

@export var message_box : VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func log(s: String) -> void:
	var label := RichTextLabel.new()
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.context_menu_enabled = true
	label.selection_enabled = true
	label.text = s
	message_box.add_child.call_deferred(label)

func log_clear() -> void:
	for i in message_box.get_children():
		message_box.remove_child(i)


func _on_button_stats_pressed() -> void:
	print("Test!!!")
	Penny.log("Test")


func _on_button_reload_pressed() -> void:
	PennyImporter.inst.reload(true)
