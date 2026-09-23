## Defines a type of decoration which can be used in penny messages.
@icon("res://addons/penny/icons/Decoration.svg")
@tool
class_name PennyDecoration
extends Resource

static var REGISTRY: Dictionary[StringName, PennyDecoration] = {}

static func add_decoration_to_registry(decoration: PennyDecoration) -> void:
	assert(
		not REGISTRY.has(decoration.id),
		"Decoration with id '%s' already exists in the registry." % [
			decoration.id,
		]
	)

	REGISTRY[decoration.id] = decoration
	decoration._ready()

static func get_decoration_by_id(id: StringName) -> PennyDecoration:
	return REGISTRY.get(id)


## Defines how to identify the decor in message text. It can also be used as an argument.
@export var id : StringName

## Defines the default values for each argument. If an argument is passed that does not match one of these keys, it will print an error, and ignore it.
@export var args : Dictionary[StringName, Variant] = {}

## This [RichTextEffect] will be installed to each [RichTextLabel] that requires this [Decor].

## If enabled, the element may be closed using `</>` (closing element). Otherwise, the element will be treated as a standalone.
@export var closable : bool = true


## If enabled, a user prod will stop at this element (even if there is more text in the [Typewriter]).
@export var prod_stop : bool = false


## This is the name of the method to call. If this is empty, the decoration will be invisible.
@export var rich_push_method : StringName


## Also, if this effect is a [PennyDecorationTextEffect], it will be handled accordingly.
@export var effect : RichTextEffect


## Called when loaded at runtime.
func _ready() -> void:
	print("Decoration ready :: %s" % self)


func _to_string() -> String:
	return "<%s/>" % id


func preprocess_start() -> void:
	pass



func populate(inst: PennyDecorationInstance) -> void:
	pass


func compile(inst: PennyDecorationInstance) -> void:
	pass
