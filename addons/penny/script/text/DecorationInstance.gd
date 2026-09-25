## A single instance of a text template.
@tool
class_name PennyDecorationInstance
extends Resource

@export
var template: PennyDecoration

@export
var args: Dictionary[StringName, Variant]


## Extra data not passed to any environment or context; for internal use only.
var data: Dictionary


var owner: Penny.Text.Tag


var id: StringName:
	get: return args.keys()[0] if args else &""


var require_rtl_context: bool:
	get: return template.require_rtl_context


func _init() -> void:
	args = {}
	data = {}


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


func has_argument(arg: StringName) -> bool:
	if args.has(arg):
		return true
	elif template.get_default_args().has(arg):
		return true
	else:
		return false


func get_argument(arg: StringName) -> Variant:
	if args.has(arg):
		return args[arg]
	elif template.get_default_args().has(arg):
		return template.get_default_args()[arg]
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

	args[arg] = value


func preprocess_start(context: Penny.Text.DecorationContext) -> void:
	template.preprocess_start(self, context)


func preprocess_end(context: Penny.Text.DecorationContext) -> void:
	template.preprocess_end(self, context)


## Push to the label. This happens during compilation, but may happen multiple times as other decorations are pushed and popped.
func build_start(context: Penny.Text.DecorationContext) -> void:
	template.build_start(self, context)


func build_end(context: Penny.Text.DecorationContext) -> void:
	template.build_end(self, context)
