## Defines a type of decoration which can be used in penny messages.
@abstract
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


## Defines how to identify the decoration in message text. It can also be used as an argument.
@export var id : StringName

## Other names to identify this decoration. These must share uniqueness amongst other tags' ids and aliases.
@export var aliases : Array[StringName]


var require_rtl_context: bool:
	get: return get_require_rtl_context() and get_closable()


@abstract
func get_args() -> Dictionary[StringName, Variant]

@abstract
func get_closable() -> bool

@abstract
func get_prod_stop() -> bool

@abstract
func get_require_rtl_context() -> bool


## Called when loaded at runtime.
func _ready() -> void:
	print("Decoration ready :: %s" % self)


func _to_string() -> String:
	return "<%s/>" % id


func preprocess_start(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext) -> void:
	pass


func preprocess_end(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext) -> void:
	pass


func build_start(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext) -> void:
	pass


func build_end(inst: PennyDecorationInstance, context: Penny.Text.DecorationContext) -> void:
	pass


func encounter_start(inst: PennyDecorationInstance) -> void:
	pass


func encounter_end(inst: PennyDecorationInstance) -> void:
	pass
