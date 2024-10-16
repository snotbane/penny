
class_name AssignmentRecord extends Object

var path_string : String
var before : Variant
var after : Variant

func _init(_path: ObjectPath, _before: Variant, _after: Variant) -> void:
	path_string = _path.to_string()
	before = _before
	after = _after

func _to_string() -> String:
	var before_string := str(before)
	if before is PennyObject:
		before_string = before.name
	elif before is String:
		before_string = "\"%s\"" % before
	var after_string := str(after)
	if after is PennyObject:
		after_string = after.name
	elif after is String:
		after_string = "\"%s\"" % after
	return "[color=#%s][code]%s[/code][/color] = [code]%s[/code] \u279e [color=#%s][code]%s[/code][/color]" % [Penny.IDENTIFIER_COLOR.to_html(), path_string, before_string, Penny.FUTURE_COLOR.to_html(), after_string]
