## Templates for special elements that interface with [Typewriter].
class_name Decor extends Resource

static var MASTER_REGISTRY : Dictionary[StringName, Decor]

static func from_id(_id: StringName) -> Decor:
	return MASTER_REGISTRY.get(_id)

static func register_in_master(dec: Decor) -> void:
	MASTER_REGISTRY[dec.id] = dec

@export var id : StringName

## Defines the default values for each argument.
@export var args : Dictionary[StringName, Variant] = {}

## This [RichTextEffect] will be installed to each [RichTextLabel] that requires this [Decor].
## Also, if this effect is a [DecorTextEffect], it will be handled accordingly.
@export var effect : RichTextEffect

## If enabled, the element may be closed using `</>` (closing element). Otherwise, the element will be treated as a standalone.
@export var closable : bool = true

## If enabled, the element will produce bbcode element(s) in the [RichTextLabel]. Otherwise, the element will be completely invisible and be processed only by the [Typewriter].
@export var bbcode : bool = true

## If enabled, a user prod will stop at this element (even if there is more text in the [Typewriter]).
@export var prod_stop : bool = false

var is_decor_text_effect : bool :
	get: return effect is DecorTextEffect

var wait_state : Typewriter.PlayState :
	get: return Typewriter.PlayState.PAUSED if prod_stop else Typewriter.PlayState.DELAYED

func get_bbcode_open(element: DecorElement) -> String:
	if not bbcode: return ""
	return _get_bbcode_open(element)
func _get_bbcode_open(element: DecorElement) -> String:
	return element.get_bbcode_open(element.args.merged(args))

func get_bbcode_close(element: DecorElement) -> String:
	if not bbcode: return ""
	return _get_bbcode_close(element)
func _get_bbcode_close(element: DecorElement) -> String:
	return element.get_bbcode_close()

func populate(element: DecorElement) -> void: pass
func compile(element: DecorElement) -> String:
	var result := _compile(element)

	if not is_decor_text_effect: return result

	element.args[&"_element"] = element.get_instance_id()

	return result
func _compile(element: DecorElement) -> String: return ""

## Hidden for efficiency. DecorElement encounters are only registered if their decor possesses these methods.
# func encounter_open(element: DecorElement) : pass
# func encounter_close(element: DecorElement) : pass
