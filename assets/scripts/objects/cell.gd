
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
var data : Dictionary[StringName, Variant]

var text : String :
	get: return get_value(Cell.K_TEXT, key_name)
var text_as_display_string : DisplayString :
	get: return DisplayString.new_from_pure(text, self)

var node_name : String :
	get: return key_name


var instance : Node :
	get: return self.get_local_value(Cell.K_INST)
	set(value): self.set_local_value(Cell.K_INST, value)


func _init(__key_name : StringName, _parent : Cell, _data : Dictionary[StringName, Variant]) -> void:
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


func _get(property: StringName) -> Variant: return get_value(property)
func _set(property: StringName, value: Variant) -> bool: set_value(property, value); return true
func _get_property_list() -> Array[Dictionary]:
	var result : Array[Dictionary] = []
	for k in data.keys():
		result.push_back({

		})
	return result


func get_value_evaluated(key: StringName, default: Variant = null) -> Variant:
	var result : Variant = self.get_value(key, default)
	return result.evaluate(self) if result is Evaluable else result


func get_base_value(key: StringName) -> Variant:
	if self.data.has(Cell.K_BASE):
		var base_ref : Path = self.data[Cell.K_BASE].duplicate()
		base_ref.ids.push_back(key)
		return base_ref.evaluate()
	else: return null


func set_value(key: StringName, value: Variant) -> void:
	self.set_local_value(key, value)


func set_local_value(key: StringName, value: Variant) -> void:
	if value == null: self.data.erase(key)
	else: data[key] = value


func add_cell(key: StringName, base: Path = null) -> Cell:
	var initial_data : Dictionary[StringName, Variant] = {}
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

	if result is Actor:
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
	if inst is Actor:
		inst.close()
	inst.queue_free()


func get_save_data() -> Variant:
	return Save.any(data)

func get_save_ref() -> Variant:
	return (Path.to(self)).get_save_data()


func load_data(host: PennyHost, json: Dictionary) -> void:
	self.close_instance()

	var result_data : Dictionary[StringName, Variant] = {}
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
		if inst_data.has(&"spawn_used") and inst_data[&"spawn_used"]:
			var node := self.instantiate(host)
			if node is Actor:
				node.load_data(inst_data)
