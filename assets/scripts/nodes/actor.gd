
## A [Node] that can/must be safely opened and closed. In [Penny], these nodes can be awaited so that the script flows together cleanly.
class_name Actor extends Node

signal advanced
signal closed
signal closing
signal opened
signal opening

## If true, the Penny script will not await anything to proceed before this node enters the scene tree. I.E. It will open on ready. If false, you'll have to manually open the node.
@export var immediate_open : bool = true
## If true, the Penny script will not await anything to proceed before this node exits the scene tree. I.E. It will queue free on close. If false, you'll have to manually queue_free the node.
@export var immediate_close : bool = true

@export_subgroup("Save Data")

## If enabled, this [PennyNode] will be instantiated when loading (and also destroyed when unloading).
@export var save_spawn : bool = true

## If enabled, this [PennyNode]'s transform will be saved.
@export var save_transform : bool = true

var host : PennyHost
var cell : Cell

var is_open : bool = false


func _ready() -> void: pass


## Called immediately after instantiation. Use to "populate" the node with specific, one-time information it may need.
func populate(_host: PennyHost, _cell: Cell = null) -> void:
	host = _host
	cell = _cell

	self.closing.connect(cell.disconnect_instance.bind(self))

	_populate()
func _populate() -> void: pass


func open(wait : bool = false) :
	opening.emit()
	if immediate_open: open_finish()
	elif wait: await opened


func open_finish() -> void:
	is_open = true
	opened.emit()


func close(wait : bool = false) :
	is_open = false
	closing.emit()
	if immediate_close: close_finish()
	elif wait: await closed

func close_finish() -> void:
	closed.emit()
	queue_free()


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
