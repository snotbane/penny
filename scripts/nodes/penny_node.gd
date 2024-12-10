
## A representation of a Penny Object.
class_name PennyNode extends Node

signal opening
signal opened
signal closing
signal closed

@export var immediate_open : bool = true
@export var immediate_close : bool = true

var host : PennyHost
var object : PennyObject

var is_open : bool = false

## Called immediately after instantiation. Use to "populate" the node with specific, one-time information it may need.
func populate(_host: PennyHost, _object: PennyObject = null) -> void:
	host = _host
	object = _object

	self.closing.connect(object.clear_instance.bind(self))

	_populate(_host, _object)
func _populate(_host: PennyHost, _object: PennyObject) -> void: pass


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
