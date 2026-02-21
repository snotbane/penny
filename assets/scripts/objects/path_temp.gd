
## Path from the root cell to another cell, or any of its properties, or any of its instance's properties.
class_name Path extends Evaluable

enum {
	DIRECT_EXPLICIT,
	DIRECT_RELATIVE,
	DIRECT_BLANK,
}

const COLOR := Color8(65, 122, 236)

static var ROOT := Path.new(PackedStringArray(), false)
static var DEFAULT_BASE := Path.new([Cell.K_OBJECT], false)
static var NEW : Path :
	get: return ROOT.duplicate()


static func to(cell: Cell, _rel: bool = false) -> Path:
	var _ids := PackedStringArray()
	var cursor := cell
	while cursor and cursor != Cell.ROOT:
		_ids.insert(0, cursor.key_name)
		cursor = cursor.parent
	return Path.new(_ids, _rel)


## Creates a new [Path] from tokens. Mainly used when parsing scripts. Removes used tokens from the passed array.
static func new_from_tokens(tokens: Array) -> Path:
	if not tokens: return Path.ROOT
	var _rel : bool = tokens[0].type == PennyScript.Token.Type.OPERATOR and tokens[0].value.type == Op.DOT
	if _rel: tokens.pop_front()

	var _ids : PackedStringArray
	var expect_dot := false
	while tokens:
		if expect_dot:
			if tokens.front().type == PennyScript.Token.Type.OPERATOR and tokens.front().value.type == Op.DOT:
				tokens.pop_front()
				expect_dot = false
				continue
			else: break
		else:
			_ids.push_back(tokens.pop_front().value)
			expect_dot = true
			continue
	return Path.new(_ids, _rel)


## Creates a new [Path] from a string. Mainly used via manual access.
static func new_from_string(s : String) -> Path:
	if s.is_empty(): return
	if s[0] == "@": s = s.substr(1)
	var _rel := s[0] == "."
	if _rel: s = s.substr(1)
	var _ids := s.split(".", false)
	return Path.new(_ids, _rel)


static func new_from_json(json: String) -> Path:
	return Path.new_from_string(json)

func export_json() -> Variant:
	var result := "." if rel else ""
	for id in ids:
		result += id + "."
	return result.substr(0, result.length() - 1)

func import_json(json: String) -> void:
	if json.is_empty(): return
	rel = json[0] == "."
	if rel: json = json.substr(1)
	ids = json.split(".", false)


var ids : PackedStringArray
var rel : bool

var is_explicit : bool :
	get: return ids.is_empty()

var directive : int :
	get: return (DIRECT_RELATIVE if rel else DIRECT_BLANK) if ids.is_empty() else DIRECT_EXPLICIT

func _init(_ids: PackedStringArray = [], _rel: bool = false) -> void:
	self.ids = _ids
	self.rel = _rel


func _to_string() -> String:
	var result := "." if self.rel else ""
	for id in self.ids:
		result += id + "."
	return "@" + result.substr(0, result.length() - 1)


func duplicate() -> Path:
	return Path.new(self.ids.duplicate(), self.rel)


func globalize(context: Cell) -> Path:
	var result := self.duplicate()
	if not self.rel: return result
	while context and context != Cell.ROOT:
		result.ids.insert(0, context.key_name)
		context = context.parent
	result.rel = false
	return result


func append(other: Path) -> Path:
	var result := self.duplicate()
	result.ids.append_array(other.ids)
	return result


func set_local_value_in_cell(context: Variant, value: Variant) -> void:
	if not rel: context = Cell.ROOT

	for i in ids.size() - 1: context = context.get_value(ids[i]) if context is Cell else context.get(ids[i])
	context.set(ids[ids.size() - 1], value)

func set_storage_in_cell(context: Variant, stored: bool) -> void:
	if not rel: context = Cell.ROOT

	for i in ids.size() -1: context = context.get_value(ids[i]) if context is Cell else context.get(ids[i])
	context.set_key_stored(ids[ids.size() - 1], stored)


func _evaluate(context: Cell) -> Variant:
	return evaluate_dynamic(context, &"get_value", &"has_value")


func evaluate_local(context := Cell.ROOT) -> Variant:
	return evaluate_dynamic(context, &"get_local_value", &"has_local_value")


func evaluate_dynamic(context: Cell, get_func: StringName, has_func: StringName) -> Variant:
	if not rel: context = Cell.ROOT
	var result : Variant = context
	var __id_previous__ : StringName
	for id in ids:
		assert(result != null, "Attempted to evaluate path '%s', but id '%s' couldn't be found." % [self, __id_previous__])
		__id_previous__ = id
		if result.has_method(id) or result.has_signal(id) or result.has_meta(id):
			# print("Path result %s has method or signal or meta: %s" % [ self, id ])
			pass
		elif result is Cell:
			if result.call(has_func, id):
				result = result.call(get_func, id)
				continue
			var inst : Node = result.instance
			if inst:
				result = inst.get(id)
				continue
		result = result.get(id)
	return result
