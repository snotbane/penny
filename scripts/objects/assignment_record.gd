
class_name AssignmentRecord extends Object

var before : Variant
var after : Variant

func _init(_before: Variant, _after: Variant) -> void:
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
	return "[code]%s[/code] \u279e [color=#%s][code]%s[/code][/color]" % [before_string, Penny.FUTURE_COLOR.to_html(), after_string]
