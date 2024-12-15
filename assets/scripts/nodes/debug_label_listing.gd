
class_name DebugLabelListing extends Control

var debug : PennyDebug
var label_penny : StringName

@export var label_node : Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func populate(_debug: PennyDebug, _label: StringName) -> void: _populate(_debug, _label)
func _populate(_debug: PennyDebug, _label: StringName) -> void:
	debug = _debug
	label_penny = _label
	label_node.text = label_penny


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_undo_button_pressed() -> void:
	PennyException.new("This button doesn't work yet.").push_error()


func _on_jump_button_pressed() -> void:
	debug.host.jump_to(label_penny)


func _on_call_button_pressed() -> void:
	debug.host.call_stack.push_back(debug.host.cursor.next_in_order)
	_on_jump_button_pressed()
