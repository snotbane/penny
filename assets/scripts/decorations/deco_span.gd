
class_name DecoSpan extends Deco

## Defines the allowed arguments and their default values. Arguments used that don't match here will be ignored.
@export var argument_defaults : Dictionary[StringName, Variant] = {}


func _to_string() -> String:
	return "<%s %s>" % [self.id, self.argument_defaults.keys()]


## What is actually written to the RichTextLabel in bbcode. Use [inst] to access arguments.
func _get_bbcode_tag_start(inst: DecoInst) -> String:
	if self.id.is_empty(): return String()
	var result := String()
	var merge := inst.args.merged(argument_defaults)
	var keys := merge.keys().duplicate()
	for k in keys:
		result += " %s=%s" % [k, Deco.convert_variant_to_bbcode(merge[k])]
	match argument_defaults.size():
		0:
			result = self.id
		1:
			result = result.substr(1)
		_:
			result = self.id + result
	return "[%s]" % result
