
class_name PromptButton extends BaseButton

@export var label : RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.resized.connect(refresh_size)
	refresh_size()

func receive(option: String) -> void:
	label.text = "[center]%s" % option

func refresh_size() -> void:
	self.custom_minimum_size.y = label.size.y
