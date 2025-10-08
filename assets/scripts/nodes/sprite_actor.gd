@tool class_name SpriteActor extends Actor

signal flag_changed(value : StringName)
signal blinking_changed(value : bool)
signal talking_changed(value : bool)

@export var voice_audio_player : Node
@export var emanata_spawner : EmanataSpawner
@export var mesh : MeshInstance3D
@export var sprite_flags : FlagController
@export var sprite_blink_anim : Node
@export var animtree : AnimationTree
@export var agent : ActorNavigationAgent3D


@export var flags : PackedStringArray :
	get:
		var result : PackedStringArray
		if sprite_flags: result = sprite_flags.flags
		else: result = []
		return result
	set(value):
		if not sprite_flags: return
		sprite_flags.flags = value


@export var is_blinking : bool :
	get: return sprite_blink_anim.is_blinking if sprite_blink_anim else false
	set(value):
		if not sprite_blink_anim: return
		sprite_blink_anim.is_blinking = value
		blinking_changed.emit(value)


@export var is_talking : bool :
	get: return sprite_flags.flags.has(&"talk") if sprite_flags else false
	set(value):
		if not sprite_flags: return
		sprite_flags.push_flag(&"talk" if value else &"silent")
		talking_changed.emit(value)
func set_is_talking(value: bool) -> void:
	is_talking = value


func _ready() -> void:
	super._ready()

	# if not self.flag_changed.is_connected(sprite_flags.push_flag):
	# 	self.flag_changed.connect(sprite_flags.push_flag)
	# 	self.talking_changed.connect(sprite_flags.set_talking_flag)


func spawn() -> void:
	mesh.opacity = 0.0


func travel(destination):
	if destination is Node3D:
		agent.move_target = destination
	elif destination is Vector3:
		agent.create_loose_local_target(destination)
	await agent.target_reached

func travel__cleanup(record: Record) -> void:
	if not agent.is_target_reached():
		self.global_position = agent.target_position
	agent.move_target = null


func face(funx: Funx, other: Cell):
	var other_inst : Node = other.instance
	assert(other_inst != null, "%s can't face towards %s because no instance has been spawned yet." % [cell, other])
	assert(other_inst is Node3D, "%s can't face towards %s because its instance is not a Node3D." % [cell, other])

	if funx.wait: await	_face(other_inst)
	else:				_face(other_inst)

func _face(other: Node3D) :
	if signf(self.global_basis.x.dot(other.global_position - self.global_position)) > 0.0: return

	animtree.is_facing_right = not animtree.is_facing_right
	await animtree.facing_finished


# var current_emanata : Node
func spawn_emanata(id : StringName, attached := false) -> void:
	emanata_spawner.spawn_emanata(id)


func get_emanata_hook(node: Node) -> Node:
	var result := self.emanata_spawner.find_child(node.name)
	return result if result else self.emanata_spawner


const emanata_paths : Dictionary[StringName, String] = {
	&"fireball": "uid://56jxmjxmj8gq",
	&"fume": "uid://sqksymjvkkg",
	&"question": "uid://b720l5iiacadm",
	&"vessel": "uid://bor78qfbly6w5",
}
