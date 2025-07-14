## Templates for special tags that interface with [Typewriter].
class_name Decor extends Resource

static var MASTER_REGISTRY : Dictionary[StringName, Decor]

static func from_id(_id: StringName) -> Decor:
	return MASTER_REGISTRY.get(_id)

static func register_in_master(dec: Decor) -> void:
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

## If enabled, this will pass the owner [Typewriter]'s instance id, as well as the tag's open and close indeces, as bbcode arguments. Use with [TypewriterTextEffect]s or other [RichTextEffect]s that require such information.
@export var is_typewriter_dependent : bool = false

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

func populate(tag: Tag) -> void: pass
func compile_for_typewriter(tag: Tag, tw: Typewriter) -> void:
	_compile_for_typewriter(tag, tw)

	if not is_typewriter_dependent: return

	tag.args[&"_tw"] = tw.get_instance_id()
	tag.args[&"_open"] = tag.open_index
	tag.args[&"_close"] = tag.close_index
func _compile_for_typewriter(tag: Tag, tw: Typewriter) -> void: pass

## Hidden for efficiency. Tag encounters are only registerd if their decor possesses these methods.
# func encounter_open(tag: Tag, tw: Typewriter) -> void : pass
# func encounter_close(tag: Tag, tw: Typewriter) -> void : pass
