
## Should be the root script of any Node that Penny opens/instantiates and needs to have any control over.
class_name PennyNode extends Node

enum AppearState {
	INITED,
	READY,
	OPENING,
	PRESENT,
	CLOSING,
	CLOSED,
}

## Emitted when this node is given the clear to transition from [member _ready] to [member _present]
signal on_open
signal on_close
signal on_present
signal advanced

## If enabled, this node will stop Penny execution when it is opened.
@export var halt_on_instantiate : bool = false

## If enabled, this node will immediately open (visually) on ready.
@export var open_on_ready  : bool = true

## If enabled, this node will immediately [member close] when its owning object instantiates a new instance of any link.
@export var close_on_unlinked : bool = false

## If enabled, this node will immediately [member queue_free] when it is [member close]d.
@export var free_on_close : bool = false

## If enabled, Penny will advance itself when this node is freed from the scene.
@export var advance_on_free : bool = false


var host : PennyHost
var object : PennyObject

## Additional data that may be submitted when this node is [member populate]d.
var attach : Variant


var _appear_state := AppearState.INITED
var appear_state : AppearState :
	get: return _appear_state
	set(value):
		if _appear_state >= value: return
		_appear_state = value

		match _appear_state:
			AppearState.READY:
				if open_on_ready:
					open()
			AppearState.OPENING:
				_open()
				on_open.emit()
			AppearState.PRESENT:
				_present()
				on_present.emit()
			AppearState.CLOSING:
				_close()
				on_close.emit()
				if free_on_close:
					queue_free()
			AppearState.CLOSED:
				_appear_state = AppearState.READY


## Called immediately after instantiation. Use to "populate" the node with specific, one-time information it may need.
func populate(_host: PennyHost, _object: PennyObject = null) -> void:
	host = _host
	object = _object
	_populate(_host, _object)
func _populate(_host: PennyHost, _object: PennyObject) -> void: pass


func _ready() -> void:
	appear_state = AppearState.READY


func _exit_tree() -> void:
	if object and object.local_instance == self:
		object.clear_instance_upstream()
	if advance_on_free:
		self.advanced.emit()


func open() -> void:
	appear_state = AppearState.OPENING
func _open() -> void: pass


func present() -> void:
	appear_state = AppearState.PRESENT
func _present() -> void: pass


func close() -> void:
	appear_state = AppearState.CLOSING
func _close() -> void: pass
