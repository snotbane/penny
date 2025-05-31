
class_name Cell extends RefCounted

## Default name of any new object.
const NEW_OBJECT_KEY_NAME := &"_NEW_OBJECT"
## The name of the root object.
const K_ROOT := &"root"
## The name of the prototype object this object is derived from.
const K_PROTOTYPE := &"prototype"
## The name of the default object (prototype of all other objects).
const K_OBJECT := &"object"
## The name of options (used in prompts).
const K_OPTION := &"option"
## The name of prompts.
const K_PROMPT := &"prompt"
## The name of dialogs.
const K_DIALOG := &"dialog"
## The color attribute.
const K_COLOR := &"color"
## String filter list attribute.
const K_FILTERS := &"filters"
const K_FILTER_PATTERN := &"pattern"
const K_FILTER_REPLACE := &"replace"
## Path to the scene which is instantiated for this object.
const K_RES := &"res"
## The name of the node which this object's instance wants to be located at. (Term comes from theater terminology.)
const K_MARK := &"mark"
## Unformatted name used to represent this object.
const K_NAME := &"name"
## Appears before the display name.
const K_PREFIX := &"prefix"
## Appears after the display name.
const K_SUFFIX := &"suffix"
const K_ICON := &"icon"
## The object's node instance, instantiated from [member K_RES]
const K_INST := &"inst"
const K_OPTIONS := &"options"
## A prompt's result.
const K_RESPONSE := &"response"
## Whether or not an option appears at all.
const K_VISIBLE := &"visible"
## Whether or not an option is able to be selected.
const K_ENABLED := &"enabled"
## Whether or not an option has been selected previously.
const K_CONSUMED := &"consumed"
## Display text used to represent this object.
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
	if self.data.has(Cell.K_PROTOTYPE):
		var base_ref : Path = self.data[Cell.K_PROTOTYPE].duplicate()
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
	if base: initial_data[Cell.K_PROTOTYPE] = base

	var result := Cell.new(key, self, initial_data)
	return result


func get_stage_node(host: PennyHost) -> Node:
	var stage = self.get_value(Cell.K_MARK)
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


func open(host: PennyHost, mark: StringName = &""):
	print("%s: Open says-a-me!" % self.key_name)

func open_undo(record: Record) -> void:
	print("%s: Open undo." % self.key_name)
