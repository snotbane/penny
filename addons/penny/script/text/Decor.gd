## Defines what a decoration should actually do.
@tool
extends Resource

@export var id : StringName

## Defines the default values for each argument. If an argument is passed that does not match one of these keys, it will print an error, and ignore it.
@export var args : Dictionary[StringName, Variant] = {}

## This [RichTextEffect] will be installed to each [RichTextLabel] that requires this [Decor].
## Also, if this effect is a [DecorTextEffect], it will be handled accordingly.
@export var effect : RichTextEffect

## If enabled, the element may be closed using `</>` (closing element). Otherwise, the element will be treated as a standalone.
@export var closable : bool = true

# ## If enabled, the element will produce bbcode element(s) in the [RichTextLabel]. Otherwise, the element will be completely invisible and be processed only by the [Typewriter].
# @export var bbcode : bool = true

## If enabled, a user prod will stop at this element (even if there is more text in the [Typewriter]).
@export var prod_stop : bool = false

##
@export var rich_push_method : StringName


func populate(inst: Penny.Text.DecInst) -> void:
	pass


func compile(inst: Penny.Text.DecInst) -> void:
	pass
