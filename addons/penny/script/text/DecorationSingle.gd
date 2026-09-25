@tool
class_name PennyDecorationSingle
extends PennyDecoration

## Defines the default values for each argument. If an argument is passed that does not match one of these keys, it will print an error, and ignore it.
@export var default_args : Dictionary[StringName, Variant] = {}
func get_default_args() -> Dictionary[StringName, Variant]:
	return default_args


## If enabled, the element may be closed using `</>` (closing element). Otherwise, the element will be treated as a standalone.
@export var closable : bool = true
func get_closable() -> bool:
	return closable

## If enabled, a user prod will stop at this element (even if there is more text in the [Typewriter]).
@export var prod_stop : bool = false
func get_prod_stop() -> bool:
	return prod_stop


## This is the name of the method to call. If this is empty, the decoration will be invisible.
@export var rich_push_method : StringName

## Also, if this effect is a [PennyDecorationTextEffect], it will be handled accordingly.
@export var effect : RichTextEffect


func get_require_rtl_context() -> bool:
	return not rich_push_method.is_empty()


func build_start(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext) -> void:
	if rich_push_method:
		context.rtl.call(rich_push_method)
