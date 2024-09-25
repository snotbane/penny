
## Location of a Statement specified by a file path and array index.
class_name Address extends Object

var path : StringName

var _index : int
var index : int :
	get: return _index
	set (value):
		_index = max(value, 0)

func _init(__path: StringName, __index: int) -> void:
	path = __path
	index = __index

func copy() -> Address:
	return Address.new(path, index)

func hash() -> int:
	return path.hash() + hash(index)

func equals(other: Address) -> bool:
	return self.hash() == other.hash()

func _to_string() -> String:
	return "%s:%s (%s)" % [path, index, Penny.get_statement_from(self).line]
