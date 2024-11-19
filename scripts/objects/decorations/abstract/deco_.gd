
class_name Deco extends Resource

static var MASTER_REGISTRY : Dictionary

## The id used in both penny and bbcode. E.g. "b", "i", "u".
@export var id : StringName

## Whether or not this inst makes use of an end inst ("</>")
var is_span : bool :
	get: return self._get_is_span()
func _get_is_span() -> bool:
	return true


func _to_string() -> String:
	return "<%s>" % self.id


func _get_bbcode_tag_start(inst: DecoInst) -> String:
	if self.id.is_empty(): return String()
	return "[%s]" % self.id


func _get_bbcode_tag_end(inst: DecoInst) -> String:
	if self.id.is_empty() or not is_span: return String()
	return "[/%s]" % self.id


func _on_register_start(message: DecoratedText, inst: DecoInst) -> void: pass


func _on_register_end(message: DecoratedText, inst: DecoInst) -> void: pass


func _on_encounter_start(typewriter: Typewriter, inst: DecoInst): pass


func _on_encounter_end(typewriter: Typewriter, inst: DecoInst): pass


static func register_instance(deco: Deco) -> void:
	Deco.MASTER_REGISTRY[deco.id] = deco


static func get_resource_by_id(_id: StringName) -> Deco:
	if MASTER_REGISTRY.has(_id):
		return MASTER_REGISTRY[_id]
	return null


static func convert_variant_to_bbcode(value: Variant) -> String:
	if value is Color:
		return "#" + value.to_html()
	return str(value)
