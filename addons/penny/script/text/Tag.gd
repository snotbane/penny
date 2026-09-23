## A group of [PennyDecoration]s.
@tool
extends Resource

enum {
	MODE_PUSH,
	MODE_POP,
	MODE_CLEAR,
}

@export_storage
var mode: int

@export_storage
var instances: Array[PennyDecorationInstance]


func _init(__mode__: int = MODE_PUSH) -> void:
	mode = __mode__
	instances = []


func _to_string() -> String:
	var result : String
	match mode:
		MODE_PUSH:
			result = "<%s>"

		MODE_POP:
			result = "</%s>"

		MODE_CLEAR:
			return "</*>"

	var instance_strings : PackedStringArray = []
	instance_strings.resize(instances.size())
	for i in instances.size():
		instance_strings[i] = str(instances[i])
	result %= " | ".join(instance_strings)
	return result


func add_decoration_instance(inst: PennyDecorationInstance) -> void:
	for d in instances:
		if inst.id == d.id:
			printerr("A duplicate decoration '%s' already exists in this tag. It will be ignored." % inst.id)
			return

	instances.push_back(inst)
