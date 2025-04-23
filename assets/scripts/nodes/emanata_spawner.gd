class_name EmanataSpawner extends Node

const EMANATA_PATHS : Dictionary[StringName, String] = {
	&"fireball": "res://assets/scenes/emanata/emanata_fireball.tscn",
	&"fume": "res://assets/scenes/emanata/emanata_fume.tscn",
	&"question": "res://assets/scenes/emanata/emanata_question.tscn",
	&"vessel": "res://assets/scenes/emanata/emanata_vessel.tscn",
}

# @export_tool_button("Expand Children") var expand_children_button := func() -> void:
# 	for id in transforms:
# 		var node := Node3D.new()
# 		node.transform = transforms[id]
# 		node.name = id
# 		self.add_child(node)
# 		node.owner = get_tree().edited_scene_root

# ## Destroys all children and records their transforms to the buffer.
# @export_tool_button("Consume Children") var consume_children_button := func() -> void:
# 	for child in get_children():
# 		transforms[child.name] = child.transform
# 		child.queue_free()

var transforms : Dictionary[StringName, Array]
var emanata_children : Dictionary[StringName, Array]

func _enter_tree() -> void:
	if Engine.is_editor_hint(): return
	consume_children()


func consume_children() -> void:
	var regex := RegEx.create_from_string(r"(.*?)_\d+$")
	for child in self.get_children():
		var match : RegExMatch = regex.search(child.name)
		var child_non_indexed_name := StringName(match.get_string(1)) if match else child.name
		if not child_non_indexed_name in transforms: transforms[child_non_indexed_name] = []
		transforms[child_non_indexed_name].push_back(child.transform)
		child.queue_free()


func _exit_tree() -> void:
	if Engine.is_editor_hint(): return
	for k in emanata_children.keys():
		clear_emanata(k)


func spawn_emanata(id: StringName) -> void:
	if id in emanata_children: clear_emanata(id)
	emanata_children[id] = []

	if not id in transforms:
		printerr("No transform for emanata id '%s' exists for this spawner. Spawning at the default location." % id)
		return

	for t in transforms[id]:
		var hook := ViewAngleScaler.new()
		hook.transform = t
		self.add_child(hook)

		var emanata_node = load(EMANATA_PATHS[id]).instantiate()
		emanata_children[id].push_back(hook if id in transforms else emanata_node)
		hook.add_child(emanata_node)


func clear_emanata(id: StringName) -> void:
	if not id in emanata_children: return
	for n in emanata_children[id]: n.queue_free()
	emanata_children.erase(id)

