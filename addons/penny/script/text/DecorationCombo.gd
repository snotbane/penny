## Creates an alias to bundle multiple decorations into one.
@tool
class_name PennyDecorationCombo
extends PennyDecoration

## A list of instances with specific, predefined arguments.
@export
var instances : Array[PennyDecorationInstance]


func get_default_args() -> Dictionary[StringName, Variant]:
	var result : Dictionary[StringName, Variant] = {}
	for inst in instances:
		result.merge(inst.args.merged(inst.template.get_default_args()))

	return result


func get_closable() -> bool:
	for inst in instances:
		if inst.template.get_closable():
			return true

	return false


func get_prod_stop() -> bool:
	for inst in instances:
		if inst.template.get_prod_stop():
			return true

	return false


func get_require_rtl_context() -> bool:
	for inst in instances:
		if inst.template.get_require_rtl_context():
			return true

	return false


func preprocess_start(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext) -> void:
	for child in instances:
		inst.args.merge(child.args)

	for child in instances:
		child.template.preprocess_start(inst, context)


func preprocess_end(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext) -> void:
	for child in instances:
		child.template.preprocess_end(inst, context)


func build_start(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext) -> void:
	for child in instances:
		child.template.build_start(inst, context)


func build_end(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext) -> void:
	for child in instances:
		child.template.build_end(inst, context)


func encounter_start(inst: PennyDecorationInstance) -> void:
	printerr("Unimplemented!")

func encounter_end(inst: PennyDecorationInstance) -> void:
	printerr("Unimplemented!")
