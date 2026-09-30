## A decoration which pushes a [RichTextEffect]. This also automatically passes itself and the [RichTextLabel] to the char_fx environment, i.e. it will work for [TypewriterTextEffect]s.
@tool
class_name PennyDecorationEffect
extends PennyDecoration


## Defines the default values for each argument. If an argument is passed that does not match one of these keys, it will print an error, and ignore it.
@export var default_args : Dictionary[StringName, Variant] = {}
func get_default_args() -> Dictionary[StringName, Variant]:
	return default_args


## If enabled, the element may be closed using `</>` (closing element). Otherwise, the element will be treated as a standalone.
@export var closable : bool = true
func get_closable() -> bool:
	return closable

## If enabled, a user poke will stop at this element (even if there is more text in the [Typewriter]).
@export var poke_stop : bool = false
func get_poke_stop() -> bool:
	return poke_stop


@export var effect: RichTextEffect
func get_require_rtl_context() -> bool:
	return effect != null


func preprocess_start(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext) -> void:
	if effect and not effect in context.rtl.custom_effects:
		context.rtl.install_effect(effect)


func build_start(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext):
	if effect:
		context.rtl.push_customfx(effect, inst.env)
