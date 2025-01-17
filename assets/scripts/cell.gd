
class_name Cell extends RefCounted

class Ref extends Evaluable:
	const COLOR := Color8(65, 122, 236)

	var ids : PackedStringArray
	var rel : bool

	func _init(s: String = "") -> void:
		if s.is_empty(): return
		rel = s[0] == "."
		s = s.substr(1 if rel else 0)
		ids = s.split(".", false)


	static func to(cell: Cell, _rel: bool = false) -> Ref:
		var ref_string := cell.key_name
		var cursor := cell.parent
		while cursor:
			ref_string = cursor.key_name + "." + ref_string
			cursor = cursor.parent
		if _rel: ref_string = "." + ref_string
		return Ref.new(ref_string)


	static func new_from_load_json(json: String) -> Ref:
		return Ref.new(json.substr(Save.REF_PREFIX.length()))


	func duplicate() -> Ref:
		var result := Ref.new()
		result.ids = self.ids.duplicate()
		result.rel = self.rel
		return result


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
	&"dialog": Ref.new("dialog"),
	&"name": "",
	&"name_prefix": "<>",
	&"name_suffix": "</>",
})
static var DIALOG := Cell.new(&"dialog", ROOT, {
	&"base": Ref.new("object"),
	&"link": "res://addons/penny_godot/assets/scenes/dialog_default.tscn",
	&"layer": 0,
})
static var PROMPT := Cell.new(&"prompt", ROOT, {
	&"base": Ref.new("object"),
	&"link": "res://addons/penny_godot/assets/scenes/prompt_default.tscn",
	&"options": [],
	# &"response": null,
})
static var OPTION := Cell.new(&"option", ROOT, {
	&"base": Ref.new("object"),
	&"enabled": true,
	&"visible": true,
	&"consumed": false
})


var key_name : StringName
var parent : Cell
var data : Dictionary


var name : Text :
	get: return Text.new(get_value_or_default(&"name", key_name))
var name_prefix : Text :
	get: return Text.new(get_value_or_default(&"name_prefix", "<>"))
var name_suffix : Text :
	get: return Text.new(get_value_or_default(&"name_suffix", "</>"))
var rich_name : Text :
	get: return Text.new(name_prefix.text + name.text + name_suffix.text)


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


func _init(_key_name : StringName, _parent : Cell, _data : Dictionary) -> void:
	key_name = _key_name
	parent = _parent
	data = _data

	if parent:
		parent.data[key_name] = self


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
