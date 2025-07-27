
## A [Node] that can/must be safely opened and closed. In [Penny], these nodes can be awaited so that the script flows together cleanly.
class_name Actor extends Node

signal advanced
signal entering
signal entered
signal exiting
signal exited

@export_subgroup("Save Data")

## If enabled, this [PennyNode] will be instantiated when loading (and also destroyed when unloading).
@export var save_spawn : bool = true

## If enabled, this [PennyNode]'s transform will be saved.
@export var save_transform : bool = true

var host : PennyHost
var cell : Cell

var is_entered : bool = false


func _ready() -> void: pass

func _exit_tree() -> void:
	if cell:
		cell.disconnect_instance(self)


## Called immediately after instantiation. Use to "populate" the node with specific, one-time information it may need.
func populate(_host: PennyHost, _cell: Cell = null) -> void:
	host = _host
	cell = _cell
	_populate()
func _populate() -> void: pass


# func spawn() -> void: pass
# func despawn() -> void: pass
func enter(f := Funx.new()) :
	entering.emit()
	if f.wait:
		await Async.all([_enter, entered])
	else:
		_enter()
		entered.emit()
	print("Enter finished: ", self.name)
	is_entered = true
func _enter() : pass


func exit(f := Funx.new()) :
	is_entered = false
	exiting.emit()
	if f.wait:
		await Async.all([_exit, exited])
	else:
		_exit()
		exited.emit()
func _exit() : pass


func play_animation_and_wait(player: AnimationPlayer, anim: StringName) :
	player.play(anim)
	var target_anim := &""
	while target_anim != anim:
		target_anim = await player.animation_finished


func get_save_data() -> Variant:
	var result : Dictionary[StringName, Variant] = {
		&"name": self.name,
		&"parent": self.get_parent().name,
		&"spawn_used": self.save_spawn,
		&"transform_used": self.save_transform,
		&"transform": self.get_save_transform_data()
	}
	return result

func load_data(json: Dictionary) -> void:
	self.name = json["name"]
	self.save_spawn = json["spawn_used"]
	self.save_transform = json["transform_used"]
	self.set_transform_data(json["transform"])


func get_save_transform_data() -> Variant:
	var this = self
	if this is Node3D:
		return this.transform
	if this is Node2D:
		return this.transform
	if this is Control:
		return this.get_transform()
	return null


func set_transform_data(json: Variant) -> void:
	if json == null: return
	# var t = JSON.parse_string(json)
	# if t is Transform3D or t is Transform2D:
	# 	self.transform = t
