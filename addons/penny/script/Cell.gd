@tool
extends Resource

static var ROOT : Penny.Cell
static var OBJECT : Penny.Cell
static var NARRATOR : Penny.Cell
static var PROMPT_ASK : Penny.Cell
static var PROMPT_SAY : Penny.Cell

static func _static_init() -> void:
	ROOT = Penny.Cell.new(&"ROOT", null)
	OBJECT = Penny.Cell.new(&"object", null)
	NARRATOR = Penny.Cell.new(&"~", null)
	PROMPT_ASK = Penny.Cell.new(&"prompt_ask", null)
	PROMPT_SAY = Penny.Cell.new(&"prompt_say", null)

	ROOT.set_data_local(&"object", OBJECT)
	ROOT.set_data_local(&"~", NARRATOR)
	ROOT.set_data_local(&"prompt_ask", PROMPT_ASK)
	ROOT.set_data_local(&"prompt_say", PROMPT_SAY)

	OBJECT.set_data_local(&"text", Penny.Express.new_or_literal_from_string(".name ?? \"Unnamed_Penny_Object\""))
	OBJECT.set_data_local(&"prompt_ask", Penny.Path.to(PROMPT_ASK))
	OBJECT.set_data_local(&"prompt_say", Penny.Path.to(PROMPT_SAY))
	OBJECT.set_data_local(&"filters", [
		Penny.Text.Filter.new(r"(?<!(?:Mx|Mr|Dr|Prof)s?)((?:[.,?!:;](?!\S))|-{2,})+[\'\")\]]?(?!$)", "$0<delay>"),
		Penny.Text.Filter.new(r"\.{2,}", "<delay=0.2 | speed=5>$0</>"),
		Penny.Text.Filter.new(r"(?<!\\)\|", "<delay>"),
		Penny.Text.Filter.new(r"(?<!\\)\/", "<wait>"),
		Penny.Text.Filter.new(r"---", "—"),
		Penny.Text.Filter.new(r"--", "–"),
		Penny.Text.Filter.new(r"(\S)\"", "$1”"),
		Penny.Text.Filter.new(r"\"", "“"),
		Penny.Text.Filter.new(r"(\S)'", "$1’"),
		Penny.Text.Filter.new(r"'", "‘"),
	])

	NARRATOR.prototype = OBJECT

	PROMPT_ASK.set_data_local(&"scene", "res://addons/penny/scene/PromptAsk.tscn")

	PROMPT_SAY.set_data_local(&"scene", "res://addons/penny/scene/PromptSay.tscn")


@export_storage
var name: StringName

@export_storage
var data_saved: Dictionary:
	get:
		var result := {}
		for k in data_saved_keys:
			if not has_data_local(k): continue
			result[k] = get_data_local(k)
		return result
	set(value):
		data_saved_keys = value.keys()
		for k in value:
			set_data_local(k, value[k])

@export_storage
var data_saved_keys: PackedStringArray

var data: Dictionary

var parent: Penny.Cell


func _init(__name__: StringName, __prototype__: Penny.Cell = OBJECT) -> void:
	name = __name__

	data = {}

	prototype = __prototype__


func _to_string() -> String:
	return name


func print_data() -> void:
	var result := "%s :: {" % self

	for key: StringName in data.keys():
		result += "\n\t%s : %s" % [
			key,
			data[key],
		]

	result += "}" if data.is_empty() else "\n}"

	print(result)


func get_is_data_saved(key: StringName) -> bool:
	return data_saved_keys.has(key)


func set_is_data_saved(key: StringName, value: bool) -> void:
	if data_saved_keys.has(key) == value: return

	if value:
		data_saved_keys.push_back(key)
	else:
		data_saved_keys.erase(key)


func has_data_local(key: StringName) -> bool:
	return data.has(key)


func get_data_local(key: StringName, default = null) -> Variant:
	return data.get(key, default)


func set_data_local(key: StringName, value) -> void:
	if value == null:
		data.erase(key)
	else:
		data[key] = value
		if value is Penny.Cell:
			if value.parent:
				value.parent.set_data_local(value.name, null)
			value.name = key
			value.parent = self


func has_data(key: StringName) -> bool:
	if data.has(key):
		return true
	elif prototype:
		return prototype.has_data(key)
	else:
		return false


func get_data(key: StringName, default = null) -> Variant:
	return data.get(key, prototype.get_data(key, default) if prototype else default)


func get_data_and_evaluate(key: StringName, default = null) -> Variant:
	return Penny.Evaluable.evaluate_any(get_data(key, default))


var prototype: Penny.Cell:
	get: return Penny.Evaluable.evaluate_any(get_data_local(&"prototype"))
	set(value): set_data_local(&"prototype", Penny.Path.to(value))


var instance: Node:
	get: return get_data_local(&"instance")
	set(value): set_data_local(&"instance", value)


var scene: PackedScene:
	get:
		assert(
			has_data(&"scene"),
			"Attempted to access Cell scene %s.%s, but this property does not exist." % [
				name,
				&"scene",
			]
		)
		assert(
			ResourceLoader.exists(get_data(&"scene")),
			"Attempted to access Cell scene %s.%s, but the resource '%s' does not exist." % [
				name,
				&"scene",
				get_data(&"scene"),
			],
		)
		return load(get_data(&"scene"))

## Name for use when interpolating [Penny.Message]s.
var display_text: Variant:
	get: return get_data(&"text", "Unnamed_Penny_Object")
	set(value): set_data_local(&"text", value)


var node_name: StringName:
	get: return name


func get_marker_node(tree_context: Node, marker_name: StringName = &"") -> Node:
	if not marker_name:
		marker_name = get_data(&"marker", &"")
		if not marker_name:
			return tree_context.get_tree().root

	for node: Node in tree_context.get_tree().get_nodes_in_group(&"marker"):
		if node.name == marker_name:
			return node

	assert(false, "Couldn't find marker node '%s'. Is it in the '%s' group?" % [
		marker_name,
		&"marker"
	])
	return null


## [member despawn]s the [member instance] if it already exists, and adds a new instance to the marker [member parent_name].
func spawn(player: PennyPlayer, record: Penny.Record, parent_name: StringName = &""):
	if instance:
		despawn(player, record)

	var parent := get_marker_node(player, parent_name)
	instance = scene.instantiate()
	instance.name = node_name

	if instance.has_method(&"spawn"):
		instance.spawn()

	parent.add_child(instance)

	return instance


## [member exit]s if not already done so, then destroys [member instance].
func despawn(player: PennyPlayer, record: Penny.Record):
	if not instance:
		return

	await exit(player, record)

	if instance.has_method(&"despawn"):
		instance.despawn(player, record)

	instance.queue_free()


## [member spawn]s an instance if it does not already exist, and instantly [member travel]s it to [param marker_name], and makes it visible.
func enter(player: PennyPlayer, record: Penny.Record, marker_name: StringName = &"", parent_name: StringName = &""):
	if not instance:
		spawn(player, record, parent_name)

	await travel(player, record, marker_name, 0.0)

	if instance.has_method(&"enter"):
		await instance.enter(player, record)
	elif instance.has_method(&"show"):
		instance.show()


## Hides the instance from view.
func exit(player: PennyPlayer, record: Penny.Record):
	if not instance:
		return

	if instance.has_method(&"exit"):
		await instance.exit(player, record)
	elif instance.has_method(&"hide"):
		instance.hide()


## Moves the [member instance] from its current [member global_position] to a [param destination]. This can be a [Node] in the same space (2D/3D), or a [String] name of a marker which points to a [Node] in the same space. This is a very "loose" method that will silently fail if most anything is wrong.
func travel(player: PennyPlayer, record: Penny.Record, destination, tween_duration := 0.0):
	if instance is not Node2D and instance is not Node3D:
		# printerr("%s can't travel because its instance is not a Node2D nor Node3D." % name)
		if instance == null:
			printerr("%s can't travel because its instance is null." % name)
		return

	if destination == null:
		printerr("%s can't travel because the destination is null." % name)
		return

	if destination is String or destination is StringName:
		destination = get_marker_node(player, destination)

	if instance is Node2D and destination is not Node2D:
		# printerr("%s can't travel because the destination is in a different space." % name)
		return

	if instance is Node3D and destination is not Node3D:
		# printerr("%s can't travel because the destination is in a different space." % name)
		return

	if instance.has_method(&"travel"):
		return await instance.travel(player, record, tween_duration)
	elif tween_duration > 0.0:
		return instance.create_tween().tween_property(
			instance,
			"global_position",
			destination.global_position,
			tween_duration
		)
	else:
		instance.global_position = destination.global_position
