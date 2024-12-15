
class_name Path extends Evaluable

var ids : Array[StringName]
var relative : bool

func _init(_ids: Array[StringName] = [], _nested : bool = false) -> void:
	ids = _ids
	relative = _nested


static func new_from_tokens(tokens: Array[Token]) -> Path:
	var _nested = tokens[0].value == '.'
	if _nested: tokens.pop_front()

	var _ids : Array[StringName]
	var l = floor(tokens.size() * 0.5) + 1
	for i in l:
		_ids.push_back(tokens[i * 2].value)
	return Path.new(_ids, _nested)


static func new_from_string(s: String) -> Path:
	assert(s[0] == '/')
	var _nested = s[1] == '.'
	if _nested: s = s.substr(2)
	else:
		s = s.substr(1)

	var _ids : Array[StringName]
	var split := s.split(".", false)
	for i in split:
		_ids.push_back(StringName(i))
	return Path.new(_ids, _nested)


static func new_from_single(s: StringName, _nested: bool = false) -> Path:
	return Path.new([s], _nested)


func _to_string() -> String:
	var result = "/"
	if self.relative: result += "."
	for id in ids:
		result += id + "."
	result = result.substr(0, result.length() - 1)
	return result


func duplicate() -> Path:
	return Path.new(ids.duplicate())


func _evaluate_shallow(context: PennyObject) -> Variant:
	return get_value_for(context)


## Evaluates till the end of only this [Path]. The result may or may not also be a [Path].
func get_value_for(context: PennyObject) -> Variant:
	if not relative:
		context = context.root
	var result : Variant = context
	for id in ids:
		if not result:
			return null
		result = result.get_value(id)
	return result


## Fully evaluates the path or a chain of paths. Never returns a [Path], but is prone to cyclical pathing.
func get_deep_value_for(context: PennyObject) -> Variant:
	var paths_used : Array[Path]
	var result : Variant = self
	while result is Path:
		if paths_used.has(result):
			PennyException.new("Cyclical path '%s' for object '%s'" % [result, context]).push_error()
			return null
		paths_used.push_back(result)
		result = result.get_value_for(context)
	return result


func set_value_for(context: PennyObject, value: Variant) -> void:
	# print("Attempting to set value on path '%s'. relative: '%s', Context: '%s', value: '%s'" % [self, relative, context, value])
	if not relative:
		context = context.root
	for i in ids.size() - 1:
		var id := ids[i]
		context = context.get_value(id)
	context.set_value(ids.back(), value)


func has_value_for(context: PennyObject) -> bool:
	var obj : PennyObject = context
	for i in ids.size() - 1:
		var id := ids[i]
		if not obj.has_local(id): return false
		obj = obj.get_value(id)
	return obj.has_local(ids.back())


func prepend(other: Path) -> Path:
	var other_ids := other.ids.duplicate()
	while other_ids:
		self.ids.push_front(other_ids.pop_back())
	self.relative = other.relative
	return self


func append(other: Path) -> Path:
	var other_ids := other.ids.duplicate()
	while other_ids:
		self.ids.push_back(other_ids.pop_front())
	return self


func save_data() -> Variant:
	return self.to_string()
