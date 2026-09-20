@tool
extends Penny.Evaluable

const DEBUG_COLOR := Color8(65, 122, 236)

static var TO_ROOT := Penny.Path.new()
static var TO_OBJECT := Penny.Path.new(["object"])

static func new_from_tokens_destructive(tokens: Array) -> Penny.Path:
	if tokens.is_empty():
		return null

	var is_relative : bool

	if tokens.front().type == PennyScript.Token.Type.OPERATOR and tokens.front().value == PennyScript.Token.Operator.DOT:
		is_relative = true
		tokens.pop_front()

	elif tokens.front().type == PennyScript.Token.Type.IDENTIFIER:
		is_relative = false

	else:
		return null

	var ids : PackedStringArray = []
	while true:
		if tokens.is_empty():
			break

		assert(tokens.front().type == PennyScript.Token.Type.IDENTIFIER, "Expected identifier after dot operator.")

		ids.push_back(tokens.pop_front().value)

		if tokens.is_empty():
			break

		if tokens.front().type == PennyScript.Token.Type.OPERATOR and tokens.front().value == PennyScript.Token.Operator.DOT:
			tokens.pop_front()
		else:
			break

	if ids:
		return Penny.Path.new(ids, is_relative)
	else:
		return null


static func new_from_string(s: String) -> Penny.Path:
	assert(not s.is_empty(), "Path string is empty.")

	var is_relative := s[0] == "."
	var ids: PackedStringArray = (s.substr(1) if is_relative else s).split(".")
	assert(not ids.has(""), "Path string contains an empty id.")

	return Penny.Path.new(ids, is_relative)


static func to(cell: Penny.Cell, relative_to := Penny.Cell.ROOT) -> Penny.Path:
	if cell == null:
		return null

	var ids: PackedStringArray = []
	var cursor := cell
	while cursor and cursor != relative_to:
		ids.insert(0, cursor.name)
		cursor = cursor.parent

	assert(
		cursor == relative_to,
		"Can't create a Penny.Path from '%s' to '%s'." % [
			relative_to,
			cell,
		]
	)

	return Penny.Path.new(ids, relative_to != Penny.Cell.ROOT)


@export_storage
var ids: PackedStringArray

@export_storage
var is_relative: bool


func _init(__ids__: PackedStringArray = [], __is_relative__: bool = false) -> void:
	ids = __ids__
	is_relative = __is_relative__


func _to_string() -> String:
	var result := "@"

	if is_relative:
		result += "."

	result += ".".join(ids)

	return result


func is_empty() -> bool:
	return ids.is_empty()


func back_key() -> StringName:
	if is_empty(): return &""
	return ids[-1]


func is_match(other: Penny.Path) -> bool:
	if (
		is_relative != other.is_relative
		or ids.size() != other.ids.size()
	):
		return false

	for i in ids.size():
		if ids[i] != other.ids[i]:
			return false

	return true


## Appends another path onto this one.
func append(other) -> void:
	if other is Penny.Path:
		ids.append_array(other.ids)

	else:
		assert(other is String or other is StringName)
		ids.append(other)



## Returns a new path resulting from [member append]ing this path onto another.
func concat(other) -> Penny.Path:
	var result : Penny.Path = duplicate_deep()
	result.append(other)
	return result


## Removes a number of ids from the path, effectively getting the parent.
func pop(count: int = 1) -> void:
	count = mini(count, ids.size())
	for i in count:
		ids.remove_at(ids.size() - 1)


## Returns a new path result from [member pop]ping this path. Effectively gets the parent.
func popped(count: int = 1) -> Penny.Path:
	var result : Penny.Path = duplicate_deep()
	result.pop(count)
	return result


func _evaluate_single(context) -> Variant:
	if not is_relative:
		context = Penny.Cell.ROOT

	for id in ids:
		assert(context is Object or context is Dictionary, "Can't evaluate path: context is not an Object or Dictionary")

		context = (
			context.get_data(id)
			if context is Penny.Cell
			else context.get(id)
		)

	return context


## Returns the value in the [Penny.Cell], but only if that Obj has an explicit value.
func evaluate_local(context = Penny.Cell.ROOT) -> Variant:
	if not is_relative:
		context = Penny.Cell.ROOT

	for id in ids:
		assert(context is Object or context is Dictionary, "Can't evaluate path: context is not an Object or Dictionary.")

		context = (
			context.get_data_local(id)
			if context is Penny.Cell
			else context.get(id)
		)

	return context


## Pushes the value through the path to set the value where it needs to go.
func push(value: Variant, context = Penny.Cell.ROOT) -> void:
	if not is_relative:
		context = Penny.Cell.ROOT

	for i in ids.size() - 1:
		assert(context is Object or context is Dictionary, "Can't push value through path: context is not an Object or Dictionary.")

		var id := ids[i]
		context = (
			context.get_data(id)
			if context is Penny.Cell
			else context.get(id)
		)

	assert(context is Object or context is Dictionary, "Can't push value through path: context is not an Object or Dictionary.")

	if context is Penny.Cell:
		context.set_data_local(ids[-1], value)
	else:
		context.set(ids[-1], value)
