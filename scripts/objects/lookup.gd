
class_name Lookup extends RefCounted

var key : StringName

var valid : bool :
	get: return LookupTable.has(key)

func _init(_key: StringName) -> void:
	key = _key

func _to_string() -> String:
	return "$" + key

func fetch() -> Variant:
	return LookupTable.get_data(key)

func open(host: PennyHost) -> Node:
	var scene : PackedScene = fetch()
	var result : Node = scene.instantiate()
	if result is Control:
		host.instantiate_parent_control.add_child.call_deferred(result)
	elif result is Node2D or result is Node3D:
		host.add_child.call_deferred(result)
	return result
