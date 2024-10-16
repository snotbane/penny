
class_name AssignmentRecord extends Object

var before : Variant
var after : Variant

func _init(_before: Variant, _after: Variant) -> void:
	before = _before
	after = _after

func _to_string() -> String:
	return "[code]%s[/code] \u279e [color=#%s][code]%s[/code][/color]" % [Penny.get_debug_string(before), Penny.FUTURE_COLOR.to_html(), Penny.get_debug_string(after)]
