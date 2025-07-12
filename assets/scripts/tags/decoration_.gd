## Templates for special tags that interface with [Typewriter].
class_name Decoration extends Resource

static var MASTER_REGISTRY : Dictionary[StringName, Decoration]

static func from_id(_id: StringName) -> Decoration:
	return MASTER_REGISTRY.get(_id)

static func register(dec: Decoration) -> void:
	MASTER_REGISTRY[dec.id] = dec

@export var id : StringName

## Defines the default values for each argument.
@export var args : Dictionary[StringName, Variant] = {}

## If enabled, the tag may be closed using `</>` (closing tag). Otherwise, the tag will be treated as a standalone.
@export var is_closable : bool = true

## If enabled, the tag will produce bbcode tag(s) in the [RichTextLabel]. Otherwise, the tag will be completely invisible and be processed only by the [Typewriter].
@export var is_bbcode : bool = true

## If enabled, a user prod will stop at this tag (even if there is more text in the [Typewriter]).
@export var is_prod_stop : bool = false

func get_bbcode_open(tag: Tag) -> String:
	if not is_bbcode: return ""
	return _get_bbcode_open(tag)
func _get_bbcode_open(tag: Tag) -> String:
	return tag.get_bbcode_open(tag.args.merged(args))

func get_bbcode_close(tag: Tag) -> String:
	if not is_bbcode: return ""
	return _get_bbcode_close(tag)
func _get_bbcode_close(tag: Tag) -> String:
	return tag.get_bbcode_close()

func register_on_creation(tag: Tag) -> void: pass
func register_tag(tag: Tag, typewriter: Typewriter) -> void: pass

func encounter_open(tag: Tag, typewriter: Typewriter) -> void : pass
func encounter_close(tag: Tag, typewriter: Typewriter) -> void : pass
