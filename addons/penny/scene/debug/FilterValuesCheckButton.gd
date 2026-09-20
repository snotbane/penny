extends CheckButton

signal text_changed(s: String)

@export
var text_enabled: String

@export
var text_disabled: String


func _init() -> void:
	toggled.connect(refresh)


func _ready() -> void:
	refresh()


func refresh(value: bool = button_pressed) -> void:
	text_changed.emit(text_enabled if value else text_disabled)
