
class_name Lookup extends RefCounted

var key : StringName


var valid : bool :
	get: return LookupTable.has(key)


func _init(_key: StringName) -> void:
	key = _key


static func new_from_string(s: String) -> Lookup:
	assert(s[0] == '$')
	return Lookup.new(s.substr(1))


func _to_string() -> String:
	return "$" + key


func fetch() -> Variant:
	return LookupTable.get_data(key)


func instantiate(_parent: Node) -> Node:
	var scene : PackedScene = fetch()
	var result : Node = scene.instantiate()
	_parent.add_child.call_deferred(result)
	return result


func save_data() -> Variant:
	return self.to_string()
