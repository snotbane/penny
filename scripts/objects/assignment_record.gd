
class_name AssignmentRecord extends Object

var path : ObjectPath
var before : Variant
var after : Variant

func _init(_path: ObjectPath, _before: Variant, _after: Variant) -> void:
	path = _path
	before = _before
	after = _after

func _to_string() -> String:
	return "[color=#%s][code]%s[/code][/color] = [code]%s[/code] \u279e [color=#%s][code]%s[/code][/color]" % [Penny.IDENTIFIER_COLOR.to_html(), path, before, Penny.FUTURE_COLOR.to_html(), after]
