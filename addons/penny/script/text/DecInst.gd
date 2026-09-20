## A single instance of a text decoration.
@tool
extends Resource

@export_storage
var decoration: Penny.Text.Decor

@export_storage
var args: Dictionary[StringName, Variant]

var id: StringName:
	get: return args[args.keys()[0]] if args else &""


func get_argument(arg: StringName) -> Variant:
	if args.has(arg):
		return args[arg]
	elif decoration.args.has(arg):
		return decoration.args[arg]
	else:
		printerr("Couldn't find argument '%s' in instance or decor." % arg)
		return null


func add_argument(arg: StringName, value: Variant) -> void:
	if args.has(arg):
		printerr("Argument '%s' already exists in the argument list." % [
			arg
		])
		return

	if not args.is_empty():
		pass

	args[arg] = value
