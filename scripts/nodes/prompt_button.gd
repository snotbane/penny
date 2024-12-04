
class_name PromptButton extends BaseButton

@export var label : RichTextLabel

var option : PennyObject

var _consumed : bool
var consumed : bool :
	get: return _consumed
	set(value):
		if _consumed == value: return
		_consumed = value

		if _consumed:
			self.modulate = Color(1, 1, 1, 0.25)
		else:
			self.modulate = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.resized.connect(refresh_size)
	refresh_size()


func receive(_option: PennyObject) -> void:
	option = _option

	self.visible = option.get_value(PennyObject.VISIBLE_KEY)
	self.disabled = not option.get_value(PennyObject.ENABLED_KEY)
	self.consumed = option.get_value(PennyObject.CONSUMED_KEY)

	label.text = "[center]%s" % DecoratedText.from_filtered(option.rich_name)


func refresh_size() -> void:
	self.custom_minimum_size.y = label.size.y


func _pressed() -> void:
	option.set_value(PennyObject.CONSUMED_KEY, true)
