
class_name Cell extends RefCounted

class Ref extends Evaluable:
	const COLOR := Color8(65, 122, 236)

	static var ROOT := Ref.new([], false)
	static var DEFAULT_BASE := Ref.new([&"object"], false)
	static var NEW : Ref :
		get: return ROOT.duplicate()

	var ids : PackedStringArray
	var rel : bool

	func _init(_ids: PackedStringArray, _rel: bool) -> void:
		self.ids = _ids
		self.rel = _rel


	static func to(cell: Cell, _rel: bool = false) -> Ref:
		var _ids : PackedStringArray
		var cursor := cell.parent
		while cursor:
			_ids.insert(0, cursor.key_name)
			cursor = cursor.parent
		return Ref.new(_ids, _rel)


	## Creates a new [Ref] from tokens. Mainly used when parsing scripts.
	static func new_from_tokens(tokens: Array) -> Ref:
		if not tokens: return Ref.ROOT
		var _rel : bool = tokens[0].type == PennyScript.Token.Type.OPERATOR and tokens[0].value.type == Expr.Op.DOT
		if _rel: tokens.pop_front()

		var _ids : PackedStringArray
		var l = floor(tokens.size() * 0.5) + 1
		for i in l: _ids.push_back(tokens[i * 2].value)
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
		return Ref.new_from_string(json.substr(Save.REF_PREFIX.length()))


	func duplicate() -> Ref:
		return Ref.new(self.ids.duplicate(), self.rel)


	func set_local_value_in_cell(context: Cell, value: Variant) -> void:
		if not rel: context = Cell.ROOT
		for i in ids.size() - 1: context = context.get_value(ids[i])
		context.set_local_value(ids[ids.size() - 1], value)

		# var cell_ref := self.duplicate()
		# cell_ref.ids.remove_at(cell_ref.ids.size() - 1)
		# var cell : Cell = cell_ref.evaluate(context)
		# cell.set_value(self.ids[self.ids.size() - 1], value)


	func _evaluate(context: Cell) -> Variant:
		if not rel: context = Cell.ROOT
		var result : Variant = context
		for id in ids:
			if result == null: return null
			result = result.get_value(id)
		return result


	func _to_string() -> String:
		var result := "." if rel else ""
		for id in ids:
			result += id + "."
		return "/" + result.substr(0, result.length() - 1)

static var ROOT := Cell.new(&"", null, {})

static var OBJECT := Cell.new(&"object", ROOT, {
	&"dialog": Ref.new_from_string("dialog"),
	&"name": "",
	&"prefix": "<>",
	&"suffix": "</>",
})
static var DIALOG := Cell.new(&"dialog", ROOT, {
	&"base": Ref.new_from_string("object"),
	&"link": "res://addons/penny_godot/assets/scenes/dialog_default.tscn",
	&"layer": 0,
})
static var PROMPT := Cell.new(&"prompt", ROOT, {
	&"base": Ref.new_from_string("object"),
	&"link": "res://addons/penny_godot/assets/scenes/prompt_default.tscn",
	&"options": [],
	# &"response": null,
})
static var OPTION := Cell.new(&"option", ROOT, {
	&"base": Ref.new_from_string("object"),
	&"enabled": true,
	&"visible": true,
	&"consumed": false
})

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


var name : String :
	get: return get_value_or_default(&"name", key_name)
var prefix : String :
	get: return get_value_or_default(&"prefix", "<>")
var suffix : String :
	get: return get_value_or_default(&"suffix", "</>")
var rich_name : String :
	get: return prefix + name + suffix


var node_name : String :
	get: return self.to_string() if key_name.is_empty() else str(key_name)
		# var n := name.to_string()
		# if n.is_empty():
		# 	return self.to_string()
		# return name.to_string()


var instance : Node :
	get: return self.get_local_value(&"inst")
	set(value): self.set_local_value(&"inst", value)


var layer : int :
	get: return get_value_or_default(&"layer", -1)


func _init(__key_name : StringName, _parent : Cell, _data : Dictionary) -> void:
	parent = _parent
	key_name = __key_name
	data = _data


func _to_string() -> String:
	return "@" + key_name


func get_value(key: StringName) -> Variant:
	return data[key] if data.has(key) else get_base_value(key)


func get_local_value(key: StringName) -> Variant:
	return data[key] if data.has(key) else null


func get_base_value(key: StringName) -> Variant:
	if self.data.has(&"base"):
		var base_ref : Ref = self.data[&"base"].duplicate()
		base_ref.ids.push_back(key)
		return base_ref.evaluate()
	else: return null


func get_value_or_default(key: StringName, default: Variant) -> Variant:
	var value : Variant = self.get_value(key)
	return value if value else default


func set_value(key: StringName, value: Variant) -> void:
	self.set_local_value(key, value)


func set_local_value(key: StringName, value: Variant) -> void:
	if value == null: self.data.erase(key)
	else: data[key] = value


func add_cell(key: StringName, base: Ref = null) -> Cell:
	var initial_data := {}
	if base: initial_data[&"base"] = base

	var result := Cell.new(key, self, initial_data)
	return result


func instantiate(host: PennyHost) -> Node:
	self.close_instance()
	var result : Node = load(get_value(&"link")).instantiate()
	host.get_layer(self.layer).add_child(result)

	if result is PennyNode:
		result.populate(host, self)

	result.tree_exiting.connect(self.disconnect_instance.bind(result))
	result.name = self.node_name
	self.instance = result
	return result


func disconnect_instance(match : Node = null) -> void:
	if match and self.instance == match: return
	self.instance = null


func close_instance() -> void:
	var inst := self.instance
	if inst == null: return
	if inst is PennyNode:
		inst.close()
	inst.queue_free()
