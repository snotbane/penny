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
	get: return template.id


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


## Sets the id if not already set.
func set_template_from_id(id: StringName) -> void:
	if template != null:
		return

	template = PennyDecoration.get_decoration_by_id(id)
	assert(
		template != null,
		"No decoration could be identified from the id '%s'. Make sure the desired decoration resource is located inside `res://addons/penny/decorations` and that it has a unique id." % [
			id
		]
	)


func add_argument(arg: StringName, value: Variant) -> void:
	if args.has(arg):
		printerr("Argument '%s' already exists in the argument list." % [
			arg
		])
		return

	args[arg] = value


## Sets args to a new dictionary with all arguments in the proper order.
func compile_args() -> void:
	# args.merge(template.get_default_args())
	args = template.get_default_args().merged(args, true)


func preprocess_start(context: Penny.Text.DecorationContext) -> void:
	template.preprocess_start(self, context)


func preprocess_end(context: Penny.Text.DecorationContext) -> void:
	template.preprocess_end(self, context)


## Push to the label. This happens during compilation, but may happen multiple times as other decorations are pushed and popped.
func build_start(context: Penny.Text.DecorationContext) -> void:
	template.build_start(self, context)


func build_end(context: Penny.Text.DecorationContext) -> void:
	template.build_end(self, context)
