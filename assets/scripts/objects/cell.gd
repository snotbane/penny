class_name Cell extends JSONResource

#region Key Constants

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
## The object's node instance, instantiated from [member K_RES], or otherwise found in the scene.
const K_INST := &"instances"
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

const DEFAULT_TRAVEL_CURVE : Curve = preload("uid://c0n3ef6ykv60w")

static var static_init_completed : bool = false

static var ROOT : Cell
static var OBJECT : Cell

static func _static_init() -> void:
	ROOT = Cell.new(&"", null, {})
	OBJECT = Cell.new(Cell.K_OBJECT, ROOT, {})

	static_init_completed = true

#endregion

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
var data_storage : Array[StringName]

var prototype : Cell :
	get:
		if not has_local_value(K_PROTOTYPE): return null
		return get_local_value(K_PROTOTYPE).duplicate().evaluate()

var key_text : String :
	get: return str(self.get_value(Cell.K_TEXT, key_name))
var text_as_display_string : DisplayString :
	get: return DisplayString.new_from_pure(key_text, self)

var node_name : String :
	get: return key_name

var instances : Variant :
	get: return self.get_local_value(Cell.K_INST)
	set(value): self.set_local_value(Cell.K_INST, value)
func add_instance(node: Node) -> void:
	if instances:
		if instances.has(node): return

		instances.push_back(node)
		instances.sort_custom(sort_instances)
	else:
		instances = [ node ]

	node.tree_exiting.connect(remove_instance.bind(node))
func remove_instance(node : Node = null) -> void:
	if not instances: return
	instances.erase(node)
	if instances.is_empty():
		set_local_value(Cell.K_INST, null)
func sort_instances(a: Node, b: Node) -> bool:
	return (a.link_priority if a is Actor else 0) > (b.link_priority if a is Actor else 0)
func assign_instances_recursive(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group(link_group_name):
		add_instance(node)
	for k in data.keys():
		if data[k] is not Cell: continue
		data[k].assign_instances_recursive(tree)

## The primary instance of this [Cell]. [Cell]s can have multiple [member instances], but only the primary instance is used. Typically you should only ever have one instance visible at a time.
var instance : Node :
	get: return instances.front() if instances else null

var link_group_name : StringName :
	get: return CellLink.GROUP_PREFIX + key_name


func _init(
	__key_name__ : StringName,
	__parent__ : Cell,
	__data__ : Dictionary
	) -> void:
	parent = __parent__
	key_name = __key_name__
	data = __data__

	if static_init_completed:
		assign_instances_recursive(Penny.inst.get_tree())


func _to_string() -> String:
	return "*%s" % key_name

#region Data Manipulation

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


## I don't think this is doing anything, but removing it throws a lot of errors. Wonderful. It's a spicy meat-a-ball in-a my spaghetti!
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
	var initial_data : Dictionary = {}
	if base: initial_data[Cell.K_PROTOTYPE] = base

	var result := Cell.new(key, self, initial_data)
	return result


var is_stored_in_parent : bool :
	get: return (parent.is_key_stored(key_name) or parent.is_stored_in_parent) if parent else false


func is_key_stored(key: StringName) -> bool:
	return is_stored_in_parent or key in data_storage or (prototype.is_key_stored(key) if prototype else false)


func set_key_stored(key: StringName, stored: bool) -> void:
	if stored == data_storage.has(key): return

	if stored:	data_storage.push_back(key)
	else:		data_storage.erase(key)

#endregion

func get_marker_node(host: PennyHost, marker_name = null) -> Node:
	if marker_name == null:
		marker_name = self.get_value(Cell.K_MARKER, Penny.DEFAULT_MARKER_NAME)
	for node in host.get_tree().get_nodes_in_group(Penny.MARKER_GROUP_NAME):
		if marker_name == node.name: return node
	assert(false, "Tried to find %s '%s', but no such marker node exists in the current scene. Make sure it belongs to the group '%s'." % ["marker" if marker_name != Penny.DEFAULT_MARKER_NAME else "default marker", marker_name, Penny.MARKER_GROUP_NAME])
	return null

func disconnect_all_instances() -> void:
	instances = []

#region Penny Methods

## [member instantiate]s a [Cell], and adds it to the appropriate parent [Node]. If it already exists, it despawns the old node and creates a new one.
func spawn(funx: Funx, parent_name = null) -> Node:
	var parent_node : Node = get_marker_node(funx.host, parent_name)

	assert(has_value(Cell.K_RES), "Attempted to instantiate cell '%s', but it does not have a [%s] attribute." % [self, Cell.K_RES])

	var res_path : String = get_value(Cell.K_RES)
	assert(ResourceLoader.exists(res_path), "Attempted to instantiate cell '%s', but its [%s] attribute does not point to a valid file path ('%s')." % [self, Cell.K_RES, res_path])

	despawn()
	var result : Node = load(res_path).instantiate()

	if result is Actor:
		result.populate(funx.host, self)

	if result.has_method(&"spawn"):
		result.spawn()

	result.name = node_name
	add_instance(result)

	if parent_node:
		parent_node.add_child(result)
		result.global_position = parent_node.global_position

	return result

func spawn__undo(record: Record) -> void:
	despawn()

func spawn__redo(record: Record) -> void:
	record.data[&"result"] = spawn.callv(record.data[&"args"])


func despawn(funx: Funx = null) -> Variant:
	var inst := instance
	if inst == null: return null
	var result := inst.get_parent().name
	if inst.has_method(&"despawn"):
		inst.despawn()
	remove_instance(inst)
	inst.queue_free()
	return result

func despawn__undo(record: Record) -> void:
	spawn(Funx.new(record.host), record.data[&"result"])

func despawn__redo(record: Record) -> void:
	record.data[&"result"] = despawn.callv(record.data[&"args"])


func enter(funx: Funx, marker_name = get_value(K_MARKER), parent_name = null) :
	var result : bool = false
	var inst : Node = instance
	if inst == null:
		assert(parent_name != null, "Cell.enter() can't be called on a Cell with no instance. Call spawn() first, or add a parent_name argument to the end of the enter() call.")
		inst = spawn(funx, parent_name)
		result = true

	if marker_name != null:
		var marker : Node = get_marker_node(funx.host, marker_name)
		inst.global_position = marker.global_position

	if inst.has_method(&"enter"):
		await inst.enter(funx)

	return result

func enter__undo(record: Record) -> void:
	exit(record.data[&"args"][0], record.data[&"result"])

func enter__redo(record: Record) -> void:
	record.data[&"result"] = await enter.callv(record.data[&"args"])


func exit(funx: Funx, __despawn__ := true) :
	var inst := instance
	if inst and inst.has_method(&"exit"):
		await inst.exit(funx)

	if __despawn__:
		return despawn()
	else:
		return null

func exit__undo(record: Record) -> void:
	if record.data[&"result"]:
		enter(record.data[&"args"][0], record.data[&"result"])
	else:
		enter(record.data[&"args"][0])

func exit__redo(record: Record) -> void:
	record.data[&"result"] = await exit.callv(record.data[&"args"])


## Moves a [Node] from one position to another. Can be a marker or a literal position. use [curve] to specify motion. [curve] should be a 1D [Curve] with a domain and range of 0.0 to 1.0.
func travel(funx: Funx, to: Variant, max_duration : float = 0.0, curve: String = "", global: bool = false):
	var inst := instance
	to = get_travel_destination(funx.host, to)
	assert(to is Node3D or to is Node2D, "TODO: travel can currently only handle a named marker Node.")

	funx.record.data[&"origin"] = inst.global_transform if global else inst.transform
	if inst.has_method(&"travel"):
		var waits : Array = [inst.travel.bind(to)]
		var timer : Timer = null

		if max_duration > 0.0:
			timer = Timer.new()
			timer.autostart = true
			timer.wait_time = max_duration
			inst.add_child(timer)
			waits.push_back(timer.timeout)

		print("Cell travel start")
		await Async.any(waits)
		print("Cell travel finish")

		if timer != null:
			timer.queue_free()
	elif max_duration > 0.0:
		var operation := TravelOperation.new(to, load(curve) if curve else DEFAULT_TRAVEL_CURVE, max_duration, global)
		inst.add_child(operation)
		operation.start()
		await operation.finished
	else:
		inst.global_position = to.global_position

func travel__cleanup(record: Record) -> void:
	var inst := instance
	if inst.has_method(&"travel"):
		assert(inst.has_method(&"travel__cleanup"), "Cell instance '%s' implements a custom travel method, but no 'travel__cleanup' method is specified.")
		inst.travel__cleanup(record)
	else:
		var operation : TravelOperation = Snotbane.find_child_of_type(inst, "TravelOperation")
		if operation: operation.finish()

func travel__undo(record: Record) -> void:
	var inst := instance
	if inst:
		inst.position = record.data[&"origin"].origin

func travel__redo(record: Record) -> void:
	var inst := instance
	if inst:
		var to = get_travel_destination(record.host, record.data[&"args"][1])
		assert(to is Node3D or to is Node2D, "TODO: travel can currently only handle a named marker Node.")

		inst.global_position = to.global_position

func get_travel_destination(host: PennyHost, to: Variant) -> Variant:
	if to is StringName or to is String:
		return get_marker_node(host, to)
	elif to is Vector3 or to is Vector2:
		return to
	assert(false, "Travel destination must be a Vector2, Vector3, or StringName of a valid travel marker.")
	return null


func reparent(funx: Funx, parent_name: StringName) -> Variant:
	var parent_node : Node = get_marker_node(funx.host, parent_name)

	var inst : Node = self.instance
	if not inst: return null

	var result := inst.get_parent().name
	var global_position_before = inst.global_position
	inst.get_parent().remove_child(inst)
	parent_node.add_child(funx.host)
	inst.global_position = global_position_before
	return result

func reparent__undo(record: Record) -> void:
	if record.data[&"result"] == null: return

	reparent(record.data[&"args"][0], record.data[&"result"])

func reparent__redo(record: Record) -> void:
	record.data[&"result"] = reparent.callv(record.data[&"args"])


func play_audio(funx: Funx, res: String) :
	var __parent__ : Node = instance if instance else funx.host
	var asp := Snotbane.create_one_shot_audio(__parent__, load(res))
	if funx.wait:	await asp.finished

#endregion

#region Serialization

func _export_json(json: Dictionary) -> void:
	json[&"storage"] = data_storage
	json[&"data"] = {}
	for k in data.keys():
		if not is_key_stored(k) and data[k] is not Cell: continue

		var serial = JSONSerialize.serialize(data[k])
		if data[k] is Cell and not serial[&"value"][&"data"]: continue

		json[&"data"][k] = serial

func _import_json(json: Dictionary) -> void:
	assert(false, "You should not be importing Cells directly. Use [import_cell] instead.")

func import_cell(json: Dictionary, host: PennyHost) -> void:
	var json_storage : Array = json[&"value"][&"storage"]
	data_storage.resize(json_storage.size())
	for i in data_storage.size(): data_storage[i] = json_storage[i]

	var json_data : Dictionary = json[&"value"][&"data"]
	for k in data.keys():
		if is_key_stored(k) and k not in json_data:
			data.erase(k)

	var inst_data : Array = []
	for k in json_data.keys():
		match k:
			K_INST:
				inst_data = json_data[k][&"value"]
			_:
				if json_data[k].get(&"script") == &"Cell":
					if not (data.has(k) and data[k] is Cell):
						data[k] = Cell.new(k, self, {})
					data[k].import_cell(json_data[k], host)
					continue

				var value = JSONSerialize.deserialize(json_data[k])
				data[k] = value

	for inst in inst_data:
		var node_data : Dictionary = inst[&"value"]
		if node_data.get(&"spawn_used"):
			var node := spawn(Funx.new(host))
			if node is Actor:
				node.import_json(node_data)

func load_data(host: PennyHost, json: Dictionary) -> void:
	self.despawn()

	var result_data : Dictionary = {}
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
					result_data[k] = JSONSerialize.deserialize(json[k])

	# Assuming all is valid. We don't want to set any data if the load fails.
	data = result_data

	if inst_data:
		# prints(self, self.local_instance)
		if inst_data.has(&"spawn_used") and inst_data[&"spawn_used"]:
			var node := self.spawn(Funx.new(host))
			if node is Actor:
				node.load_data(inst_data)

#endregion
