
class_name Cell extends JSONResource

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
const K_MARKER := &"marker"
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
## Display key_text used to represent this object.
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

var prototype : Cell :
	get:
		var result_path : Path = self.get_local_value(K_PROTOTYPE)
		return result_path.duplicate().evaluate() if result_path else null

var key_text : String :
	get: return self.get_value(Cell.K_TEXT, key_name)
var text_as_display_string : DisplayString :
	get: return DisplayString.new_from_pure(key_text, self)

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
	return "*%s" % key_name


func get_local_value(key: StringName, default: Variant = null) -> Variant:
	var result : Variant = data[key] if self.has_local_value(key) else null
	return default if result == null else result


func get_value(key: StringName, default : Variant = null) -> Variant:
	var result : Variant = data[key] if self.has_local_value(key) else self.get_base_value(key)
	return default if result == null else result


func has_local_value(key: StringName) -> bool:
	return data.has(key)


func has_value(key: StringName) -> bool:
	return self.has_local_value(key) or (self.prototype.has_value(key) if self.prototype else false)

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


func get_marker_node(host: PennyHost, marker_name: StringName = self.get_value(Cell.K_MARKER, Penny.DEFAULT_MARKER_NAME)) -> Node:
	for node in host.get_tree().get_nodes_in_group(Penny.STAGE_GROUP_NAME):
		if marker_name == node.name: return node
	return host.get_tree().root


## [member instantiate]s a [Cell], and adds it to the appropriate parent [Node]. If it already exists, it despawns the old node and creates a new one.
func spawn(funx: Funx, parent_name: StringName = get_value(K_MARKER)) -> Node:
	var parent_node : Node = get_marker_node(funx.host, parent_name if parent_name else get_value(K_MARKER))

	if not has_value(Cell.K_RES):
		printerr("Attempted to instantiate cell '%s', but it does not have a [%s] attribute." % [self, Cell.K_RES])

	var res_path : String = get_value(Cell.K_RES)
	if not ResourceLoader.exists(res_path):
		printerr("Attempted to instantiate cell '%s', but its [%s] attribute does not point to a valid file path ('%s')." % [self, Cell.K_RES, res_path])

	despawn()
	var result : Node = load(res_path).instantiate()

	if result is Actor:
		result.populate(funx.host, self)
	if result.has_method(&"spawn"):
		result.spawn()

	result.tree_exiting.connect(disconnect_instance.bind(result))
	result.name = node_name
	instance = result

	parent_node.add_child(result)
	result.global_position = parent_node.global_position

	return result
func spawn_undo(record: Record) -> void:
	print("%s: Spawn undo." % key_name)


func disconnect_instance(match : Node = null) -> void:
	if match == null or instance == match:
		instance = null


func despawn(funx: Funx = null) -> void:
	var inst := instance
	if inst == null: return
	if inst.has_method(&"despawn"):
		inst.despawn()
	inst.queue_free()
func despawn_undo(record: Record) -> void:
	print("%s: Despawn undo." % key_name)


func enter(funx: Funx, parent_name: StringName = get_value(K_MARKER)) :
	var inst := spawn(funx, parent_name)
	if inst.has_method(&"enter"):
		await inst.enter(funx)
func enter_undo(record: Record) -> void:
	print("%s: Enter undo." % key_name)


func exit(funx: Funx, __despawn__ := true) :
	var inst := instance
	if inst and inst.has_method(&"exit"):
		await inst.exit(funx)
	if __despawn__:
		despawn()
func exit_undo(record: Record) -> void:
	print("%s: Exit undo." % self.key_name)


## Moves (crosses) a Node from one position to another. Can be a marker or a literal position.
func cross(funx: Funx, to: Variant, curve: Variant):
	print("%s: cross (to: %s, curve: %s)" % [self.key_name, str(to), curve])
func cross_undo(record: Record) -> void:
	print("%s: cross undo." % self.key_name)


func reparent(funx: Funx, parent_name: StringName):
	var parent_node : Node = get_marker_node(funx.host, parent_name)

	var inst : Node = self.instance
	if not inst: return

	var global_position_before = inst.global_position
	inst.get_parent().remove_child(inst)
	parent_node.add_child(funx.host)
	inst.global_position = global_position_before
func reparent_undo(record: Record) -> void:
	print("%s: reparent undo." % self.key_name)



func _export_json(json: Dictionary) -> void:
	var keep := {}
	for k in data.keys():
		# if str(k)[0] != "$": continue
		keep[k] = data[k]
	json.merge(Save.any(keep))


func get_save_data() -> Variant:
	return Save.any(data)

func get_save_ref() -> Variant:
	return (Path.to(self)).get_save_data()


func load_data(host: PennyHost, json: Dictionary) -> void:
	self.despawn()

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
			var node := self.spawn(Funx.new(host))
			if node is Actor:
				node.load_data(inst_data)
