## A group of [PennyDecoration]s.
@tool
extends Resource

enum {
	MODE_PUSH,
	MODE_POP,
	MODE_CLEAR,
}

class Stack \
extends Resource:
	@export_storage
	var list: Array[Penny.Text.Tag]

	func _init() -> void:
		list = []

	func _iter_get(iter: Variant) -> Penny.Text.Tag:
		return list[iter]

	func _iter_init(iter: Array) -> bool:
		iter[0] = 0
		return iter[0] < list.size()

	func _iter_next(iter: Array) -> bool:
		iter[0] += 1
		return iter[0] < list.size()


	func is_empty() -> bool:
		return list.is_empty()


	func size() -> int:
		return list.size()


	func push(tag: Penny.Text.Tag) -> void:
		if tag == null:
			return

		list.push_back(tag)


	func pop() -> Penny.Text.Tag:
		return list.pop_back()


	func erase(tag: Penny.Text.Tag):
		list.erase(tag)


	func clear() -> void:
		list.clear()


	func find_tag_from_instance(query: PennyDecorationInstance) -> Penny.Text.Tag:
		for tag in list:
			for inst in tag:
				if inst == query:
					return tag

		assert(false, "Couldn't find query %s in tag list. This should not happen." % query)
		return null


	func find_associated_end_tag(query: PennyDecorationInstance) -> Penny.Text.Tag:
		return null


	func find_recent_if_instance(query: PennyDecorationInstance) -> PennyDecorationInstance:
		var this_tag := find_tag_from_instance(query)
		var i := list.find(this_tag)
		while i > 0:
			i -= 1
			for inst in list[i]:
				if inst.id != &"if":
					continue

				# if inst.has_argument(&"conditional_end"):
				# 	continue

				return inst

		return null


	func find_at_string_position(position: int) -> Penny.Text.Tag:
		for tag in list:
			if tag.position == position:
				return tag

		return null

	func erase_position_range(start: int, end: int) -> void:
		var to_remove : Array[Penny.Text.Tag] = []
		for tag in list:
			if tag.position < start:
				continue

			elif tag.position > end:
				tag.position -= end - start
				continue

			else:
				to_remove.push_back(tag)

		for tag in to_remove:
			erase(tag)


@export_storage
var position: int

@export_storage
var mode: int

@export_storage
var instances: Array[PennyDecorationInstance]


var implicit: bool:
	get: return instances.is_empty()


func _init(__position__: int = -1, __mode__: int = MODE_PUSH) -> void:
	position = __position__
	mode = __mode__
	instances = []


func _iter_get(iter: Variant) -> PennyDecorationInstance:
	return instances[iter]

func _iter_init(iter: Array) -> bool:
	iter[0] = 0
	return iter[0] < instances.size()

func _iter_next(iter: Array) -> bool:
	iter[0] += 1
	return iter[0] < instances.size()


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


func push(inst: PennyDecorationInstance, set_owner: bool = true) -> void:
	for d in instances:
		if inst.id == d.id:
			printerr("A duplicate decoration '%s' already exists in this tag. It will be ignored." % inst.id)
			return

	instances.push_back(inst)
	if set_owner:
		inst.owner = self
