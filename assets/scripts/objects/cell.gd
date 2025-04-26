
class_name Cell extends RefCounted

const NEW_OBJECT_KEY_NAME := &"_NEW_OBJECT"
const K_ROOT := &"root"
const K_OBJECT := &"object"
const K_OPTION := &"option"
const K_PROMPT := &"prompt"
const K_DIALOG := &"dialog"
const K_ABLE := &"able"
const K_BASE := &"base"
const K_COLOR := &"color"
const K_FILTERS := &"filters"
const K_FILTER_PATTERN := &"pattern"
const K_FILTER_REPLACE := &"replace"
const K_RES := &"res"
const K_STAGE := &"stage"
const K_NAME := &"name"
const K_PREFIX := &"prefix"
const K_SUFFIX := &"suffix"
const K_ICON := &"icon"
const K_INST := &"inst"
const K_OPTIONS := &"options"
const K_RESPONSE := &"response"
const K_VISIBLE := &"visible"
const K_ENABLED := &"enabled"
const K_CONSUMED := &"consumed"
const K_TEXT := &"text"

class Ref extends Evaluable:
	const COLOR := Color8(65, 122, 236)

	static var ROOT := Ref.new([], false)
	static var DEFAULT_BASE := Ref.new([Cell.K_OBJECT], false)
	static var NEW : Ref :
		get: return ROOT.duplicate()

	var ids : PackedStringArray
	var rel : bool

	func _init(_ids: PackedStringArray, _rel: bool) -> void:
		self.ids = _ids
		self.rel = _rel


	static func to(cell: Cell, _rel: bool = false) -> Ref:
		var _ids : PackedStringArray
		var cursor := cell
		while cursor and cursor != Cell.ROOT:
			_ids.insert(0, cursor.key_name)
			cursor = cursor.parent
		return Ref.new(_ids, _rel)


	## Creates a new [Ref] from tokens. Mainly used when parsing scripts. Removes used tokens from the passed array.
	static func new_from_tokens(tokens: Array) -> Ref:
		if not tokens: return Ref.ROOT
		var _rel : bool = tokens[0].type == PennyScript.Token.Type.OPERATOR and tokens[0].value.type == Expr.Op.DOT
		if _rel: tokens.pop_front()

		var _ids : PackedStringArray
		var expect_dot := false
		while tokens:
			if expect_dot:
				if tokens.front().type == PennyScript.Token.Type.OPERATOR and tokens.front().value.type == Expr.Op.DOT:
					tokens.pop_front()
					expect_dot = false
					continue
				else: break
			else:
				_ids.push_back(tokens.pop_front().value)
				expect_dot = true
				continue

		return Ref.new(_ids, _rel)


	## Creates a new [Ref] from a string. Mainly used via manual access.
	static func new_from_string(s : String) -> Ref:
		if s.is_empty(): return
		var _rel := s[0] == "."
		s = s.substr(1 if _rel else 0)
		var _ids := s.split(".", false)
		return Ref.new(_ids, _rel)


	## Creates a new [Ref] from a json string. Mainly used in saving/loading data.
	static func new_from_load_json(json: String) -> Ref:
		return Ref.new_from_string(json.substr(Save.REF_PREFIX.length() + 1))
	func get_save_data() -> Variant:
		return Save.REF_PREFIX + self.to_string()


	func _to_string() -> String:
		var result := "." if self.rel else ""
		for id in self.ids:
			result += id + "."
		return "@" + result.substr(0, result.length() - 1)


	func duplicate() -> Ref:
		return Ref.new(self.ids.duplicate(), self.rel)


	func globalize(context: Cell) -> Ref:
		var result := self.duplicate()
		if not self.rel: return result
		while context and context != Cell.ROOT:
			result.ids.insert(0, context.key_name)
			context = context.parent
		result.rel = false
		return result


	func append(other: Ref) -> Ref:
		var result := self.duplicate()
		result.ids.append_array(other.ids)
		return result


	func set_local_value_in_cell(context: Cell, value: Variant) -> void:
		if not rel: context = Cell.ROOT
		for i in ids.size() - 1: context = context.get_value(ids[i])
		context.set_local_value(ids[ids.size() - 1], value)


	func _evaluate(context: Cell) -> Variant:
		if not rel: context = Cell.ROOT
		var result : Variant = context
		for id in ids:
			result = result.get_value(id)
		return result


	func evaluate_local(context := Cell.ROOT) -> Variant:
		if not rel: context = Cell.ROOT
		var result : Variant = context
		for id in ids:
			result = result.get_local_value(id)
		return result


static var ROOT := Cell.new(&"", null, {})
static var OBJECT := Cell.new(Cell.K_OBJECT, ROOT, {})

var _key_name : StringName
var key_name : StringName :
	get: return _key_name
	set(value):
		if _key_name == value: return

		if parent:
			parent.set_local_value(_key_name, null)

		_key_name = value

		if parent:
			parent.set_local_value(_key_name, self)

var parent : Cell
var data : Dictionary

var text : String :
	get: return get_value(Cell.K_TEXT, key_name)
var text_as_display_string : DisplayString :
	get: return DisplayString.new_from_pure(text, self)

var node_name : String :
	get: return key_name


var instance : Node :
	get: return self.get_local_value(Cell.K_INST)
	set(value): self.set_local_value(Cell.K_INST, value)


func _init(__key_name : StringName, _parent : Cell, _data : Dictionary) -> void:
	parent = _parent
	key_name = __key_name
	data = _data


func _to_string() -> String:
	return "&" + key_name


func get_local_value(key: StringName, default: Variant = null) -> Variant:
	var result : Variant = data[key] if data.has(key) else null
	return default if result == null else result


func get_value(key: StringName, default : Variant = null) -> Variant:
	var result : Variant = data[key] if data.has(key) else get_base_value(key)
	return default if result == null else result


func get_value_evaluated(key: StringName, default: Variant = null) -> Variant:
	var result : Variant = self.get_value(key, default)
	return result.evaluate(self) if result is Evaluable else result


func get_base_value(key: StringName) -> Variant:
	if self.data.has(Cell.K_BASE):
		var base_ref : Ref = self.data[Cell.K_BASE].duplicate()
		base_ref.ids.push_back(key)
		return base_ref.evaluate()
	else: return null


func set_value(key: StringName, value: Variant) -> void:
	self.set_local_value(key, value)


func set_local_value(key: StringName, value: Variant) -> void:
	if value == null: self.data.erase(key)
	else: data[key] = value


func add_cell(key: StringName, base: Ref = null) -> Cell:
	var initial_data := {}
	if base: initial_data[Cell.K_BASE] = base

	var result := Cell.new(key, self, initial_data)
	return result


func get_stage_node(host: PennyHost) -> Node:
	var stage = self.get_value(Cell.K_STAGE)
	print(stage)
	if stage == null: return null
	for node in host.get_tree().get_nodes_in_group(Penny.STAGE_GROUP_NAME):
		if stage == node.name: return node
	return host.get_tree().root


func instantiate(host: PennyHost) -> Node:
	if self.get_value(Cell.K_RES) == null:
		printerr("Attempted to instantiate cell '%s', but it does not have a '%s' attribute." % [self, Cell.K_RES])
		return null

	self.close_instance()
	var result : Node = load(get_value(Cell.K_RES)).instantiate()
	var stage : Node = self.get_stage_node(host)
	if stage != null:
		stage.add_child(result)

	if result is CellNode:
		result.populate(host, self)

	result.tree_exiting.connect(self.disconnect_instance.bind(result))
	result.name = self.node_name
	self.instance = result
	return result


func disconnect_instance(match : Node = null) -> void:
	if match == null or self.instance == match:
		self.instance = null


func close_instance() -> void:
	var inst := self.instance
	if inst == null: return
	if inst is CellNode:
		inst.close()
	inst.queue_free()


func get_save_data() -> Variant:
	return Save.any(data)

func get_save_ref() -> Variant:
	return (Cell.Ref.to(self)).get_save_data()


func load_data(host: PennyHost, json: Dictionary) -> void:
	self.close_instance()

	var result_data := {}
	var inst_data : Dictionary
	for k in json.keys():
		match k:
			K_INST:
				inst_data = json[k]
			_:
				if json[k] is Dictionary:
					var cell : Cell = data[k] if data.has(k) else Cell.new(k, self, {})
					cell.load_data(host, json[k])
					result_data[k] = cell
				else:
					result_data[k] = Load.any(json[k])

	# Assuming all is valid. We don't want to set any data if the load fails.
	data = result_data

	if inst_data:
		# prints(self, self.local_instance)
		if inst_data.has("spawn_used") and inst_data["spawn_used"]:
			var node := self.instantiate(host)
			if node is CellNode:
				node.load_data(inst_data)
