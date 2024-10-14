
class_name AssignmentRecord extends Object

var key : StringName
var before : Variant
var after : Variant

func _init(_key: StringName, _before: Variant, _after: Variant) -> void:
	key = _key
	before = _before
	after = _after

func _to_string() -> String:
	return "[color=#%s][code]%s[/code][/color] = [code]%s[/code] \u279e [color=#%s][code]%s[/code][/color]" % [Penny.IDENTIFIER_COLOR.to_html(), key, before, Penny.FUTURE_COLOR.to_html(), after]
