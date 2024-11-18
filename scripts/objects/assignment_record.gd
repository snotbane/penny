
class_name AssignmentRecord extends Object

var before : Variant
var after : Variant

func _init(_before: Variant, _after: Variant) -> void:
	before = _before
	after = _after

func _to_string() -> String:
	return " [color=#%s][code]%s[/code][/color]  \u2b60  [code]%s[/code]" % [Penny.FUTURE_COLOR.to_html(), Penny.get_debug_string(after), Penny.get_debug_string(before)]
