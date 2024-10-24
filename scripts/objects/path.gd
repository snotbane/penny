
class_name Path extends Evaluable

var ids : Array[StringName]
var nested : bool

func _init(_ids: Array[StringName] = [], _nested : bool = false) -> void:
	ids = _ids
	nested = _nested

static func from_tokens(tokens: Array[Token]) -> Path:
	var _nested = tokens[0].value == '.'
	if _nested: tokens.pop_front()

	var _ids : Array[StringName]
	var l = floor(tokens.size() * 0.5) + 1
	for i in l:
		_ids.push_back(tokens[i * 2].value)
	return Path.new(_ids, _nested)

static func from_string(s: String) -> Path:
	var _nested = s[0] == '.'
	if _nested: s = s.substr(1)

	var _ids : Array[StringName]
	var split := s.split(".", false)
	for i in split:
		_ids.push_back(StringName(i))
	return Path.new(_ids, _nested)

static func from_single(s: StringName, _nested: bool = false) -> Path:
	return Path.new([s], _nested)

func _to_string() -> String:
	var result := ""
	for i in ids:
		result += "." + i
	if nested:
		return result
	else:
		return result.substr(1)


func duplicate() -> Path:
	return Path.new(ids.duplicate())


## Evaluates till the end of only this [Path]. The result may or may not also be a [Path].
func get_value_for(root: PennyObject) -> Variant:
	var result : Variant = root
	for id in ids:
		result = result.get_local_from_key(id)
	return result


## Fully evaluates the path or a chain of paths. Never returns a [Path], but is prone to cyclical pathing.
func get_deep_value_for(root: PennyObject) -> Variant:
	var paths_used : Array[Path]

	var result : Variant = self
	while result is Path:
		if paths_used.has(result):
			PennyException.new("Cyclical path '%s' for object '%s'" % [result, root]).push()
			return null
		paths_used.push_back(result)
		result = result.get_value_for(root)
	return result


func set_value_for(root: PennyObject, value: Variant) -> void:
	var obj : PennyObject = root
	for i in ids.size() - 1:
		var id := ids[i]
		obj = obj.get_local_from_key(id)
	obj.set_local_from_key(ids.back(), value)


func has_value_for(root: PennyObject) -> bool:
	var obj : PennyObject = root
	for i in ids.size() - 1:
		var id := ids[i]
		if not obj.has_local(id): return false
		obj = obj.get_local_from_key(id)
	return obj.has_local(ids.back())


func prepend(other: Path) -> Path:
	var other_ids := other.ids.duplicate()
	while other_ids:
		self.ids.push_front(other_ids.pop_back())
	self.nested = other.nested
	return self


func append(other: Path) -> Path:
	var other_ids := other.ids.duplicate()
	while other_ids:
		self.ids.push_back(other_ids.pop_front())
	return self
