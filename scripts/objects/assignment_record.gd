
class_name AssignmentRecord extends Object

var key : StringName
var before : Variant
var after : Variant

func _init(_key: StringName, _before: Variant, _after: Variant) -> void:
	key = _key
	before = _before
	after = _after

func _to_string() -> String:
	return "assigned '%s' : %s => %s" % [key, before, after]
