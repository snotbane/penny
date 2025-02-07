
extends PennyPromptButton

@export var label : RichTextLabel

func _ready() -> void:
	super._ready()
	label.resized.connect(refresh_size)
	refresh_size()


func _set_consumed(value: bool) -> void:
	if value:
		self.modulate = Color(1, 1, 1, 0.25)
	else:
		self.modulate = Color.WHITE


func _populate() -> void:
	self.visible = cell.get_value_evaluated(Cell.K_VISIBLE, true)
	self.disabled = not cell.get_value_evaluated(Cell.K_ENABLED, true)
	self.consumed = cell.get_value_evaluated(Cell.K_CONSUMED, false)

	label.text = DisplayString.new_from_pure(cell.get_value_evaluated(Cell.K_TEXT), Cell.ROOT, cell).text


func refresh_size() -> void:
	self.custom_minimum_size.y = label.size.y


func _pressed() -> void:
	cell.set_value(Cell.K_CONSUMED, true)