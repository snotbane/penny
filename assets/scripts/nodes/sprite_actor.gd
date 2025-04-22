
@tool class_name SpriteActor extends CellNode

signal flag_changed(value : StringName)
signal blinking_changed(value : bool)
signal talking_changed(value : bool)

@export var voice_audio_player : Node
@export var emanata_group : Node
@export var sprite_flags : FlagController
@export var sprite_blink_anim : Node


@export var current_flags : Array[StringName] :
	get:
		var result : Array[StringName]
		if sprite_flags: result = sprite_flags.current_flags
		else: result = []
		return result
	set(value):
		if not sprite_flags: return
		sprite_flags.current_flags = value


@export var is_blinking : bool :
	get: return sprite_blink_anim.is_blinking if sprite_blink_anim else false
	set(value):
		if not sprite_blink_anim: return
		sprite_blink_anim.is_blinking = value
		blinking_changed.emit(value)


@export var is_talking : bool :
	get: return sprite_flags.has_current_flag(&"talk") if sprite_flags else false
	set(value):
		if not sprite_flags: return
		sprite_flags.set_current_flag(&"talk" if value else &"silent")
		talking_changed.emit(value)



func _ready() -> void:
	super._ready()

	# if not self.flag_changed.is_connected(sprite_flags.set_current_flag):
	# 	self.flag_changed.connect(sprite_flags.set_current_flag)
	# 	self.talking_changed.connect(sprite_flags.set_talking_flag)


func set_is_talking(value: bool) -> void:
	is_talking = value


var current_emanata : Node
func spawn_emanata(id : StringName, attached := false) -> void:
	clear_emanata()
	current_emanata = load(emanata_paths[id]).instantiate()
	self.tree_exiting.connect(current_emanata.queue_free)
	var hook := get_emanata_hook(current_emanata)
	if attached:
		hook.add_child(current_emanata)
	else:
		self.get_tree().root.add_child(current_emanata)
		current_emanata.global_transform = hook.global_transform


func clear_emanata() -> void:
	if current_emanata: current_emanata.queue_free()


func get_emanata_hook(node: Node) -> Node:
	var result := self.emanata_group.find_child(node.name)
	return result if result else self.emanata_group


const emanata_paths : Dictionary[StringName, String] = {
	&"question": "res://assets/scenes/emanata/emanata_question.tscn",
	&"vessel": "res://assets/scenes/emanata/emanata_vessel.tscn",
}