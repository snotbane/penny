## A single instance of a text template.
@tool
class_name PennyDecorationInstance
extends Resource

@export
var template: PennyDecoration

@export
var args: Dictionary[StringName, Variant]

var id: StringName:
	get: return args.keys()[0] if args else &""


var require_rtl_context: bool:
	get:
		return not template.rich_push_method.is_empty() and template.closable


func _to_string() -> String:
	var results : PackedStringArray = []
	for arg in args:
		if args[arg] == true:
			results.push_back(arg)

		else:
			results.push_back(
				"%s=%s" % [
					arg,
					args[arg],
				]
			)

	return " ".join(results)


func get_argument(arg: StringName) -> Variant:
	if args.has(arg):
		return args[arg]
	elif template.args.has(arg):
		return template.args[arg]
	else:
		printerr("Couldn't find argument '%s' in instance or decor." % arg)
		return null


func add_argument(arg: StringName, value: Variant) -> void:
	if args.has(arg):
		printerr("Argument '%s' already exists in the argument list." % [
			arg
		])
		return

	if args.is_empty():
		template = PennyDecoration.get_decoration_by_id(arg)
		if template == null:
			printerr("No decoration could be identified from the id '%s'. Make sure the desired decoration resource is located inside `res://addons/penny/decorations` and that it has a unique id." % arg)
			return

		template.populate(self)

	args[arg] = value


## Push to the label. This happens during compilation, but
func push_to_rtl(rtl: RichTextLabel) -> void:
	if template.rich_push_method:
		rtl.call(template.rich_push_method)


func pop_to_rtl(rtl: RichTextLabel) -> void:
	pass
