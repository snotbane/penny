
## Location of a Statement specified by a file path and array index.
class_name Address extends Object

var path : StringName

var _index : int
var index : int :
	get: return _index
	set (value):
		_index = max(value, 0)

var stmt : Stmt :
	get:
		if valid:
			return Penny.stmt_dict[path][index]
		return null

var valid : bool :
	get:
		if Penny.stmt_dict.has(path):
			if index < Penny.stmt_dict[path].size():
				return true
		return false

func _init(__path: StringName, __index: int) -> void:
	path = __path
	index = __index

func copy(offset: int = 0) -> Address:
	return Address.new(path, index + offset)

func hash() -> int:
	return path.hash() + hash(index)

func equals(other: Address) -> bool:
	return self.hash() == other.hash()

func _to_string() -> String:
	return "%s:%s (ln %s)" % [path, index, stmt.line]
