
## Location of a Statement specified by a file path and array index.
class_name Address extends RefCounted

var path : StringName

var index : int

var stmt : Stmt_ :
	get:
		if valid:
			return Penny.stmt_dict[path][index]
		return null

var valid : bool :
	get:
		if Penny.stmt_dict.has(path):
			return index >= 0 and index < Penny.stmt_dict[path].size()
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
