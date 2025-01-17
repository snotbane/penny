
## A representation of a Penny Object.
class_name PennyNode extends Node

signal advanced
signal closed
signal closing
signal opened
signal opening

@export var immediate_open : bool = true
@export var immediate_close : bool = true

@export_subgroup("Save Data")

@export var save_spawn : bool = true
@export var save_transform : bool = true

var host : PennyHost
var cell : Cell

var is_open : bool = false

## Called immediately after instantiation. Use to "populate" the node with specific, one-time information it may need.
func populate(_host: PennyHost, _cell: Cell = null) -> void:
	host = _host
	cell = _cell

	self.closing.connect(cell.disconnect_instance.bind(self))

	_populate(_host, _cell)
func _populate(_host: PennyHost, _cell: Cell) -> void: pass


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


func save_data() -> Variant:
	return {
		"name": self.name,
		"parent": self.get_parent().name,
		"spawn_used": self.save_spawn,
		"transform_used": self.save_transform,
		"transform": self.get_save_transform_data()
	}

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
