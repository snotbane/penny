
## Should be the root script of any Node that Penny opens/instantiates and needs to have any control over.
class_name PennyNode extends Node

enum AppearState {
	INITED,
	READY,
	OPENING,
	OPENED,
	CLOSING,
	CLOSED,
}

enum AdvanceEvent {
	## Triggers after the node is [member _populate]d (init'd).
	IMMEDIATE,
	## Triggers after [member _ready]
	ON_READY,
	## Triggers when [member open] starts.
	ON_OPENING,
	## Triggers after [member opened]
	ON_OPENED,
	## Triggers when [member close] starts.
	ON_CLOSING,
	## Triggers after [member close] finishes.
	ON_CLOSED,
	## Triggers on [member tree_exiting]
	ON_EXITING,
	## Does not trigger on any predefined event; instead leaves it to the user to define when [member advanced] is emitted.
	CUSTOM,
}

## Emitted when this node is given the clear to transition from [member _ready] to [member _finish_open]
signal opening
signal opened
signal closing
signal closed
signal advanced

@export var advance_event := AdvanceEvent.ON_READY

## If enabled, this node will immediately open (visually) on ready.
@export var open_on_ready  : bool = true

## If enabled, this node will immediately [member queue_free] when it is [member closed].
@export var free_on_closed : bool = true


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
				if advance_event == AdvanceEvent.ON_READY:
					advanced.emit()
				if open_on_ready:
					open()
			AppearState.OPENING:
				_open()
				if advance_event == AdvanceEvent.ON_OPENING:
					advanced.emit()
				opening.emit()
				if opening.get_connections().size() == 0:
					finish_open.call_deferred()
			AppearState.OPENED:
				_finish_open()
				if advance_event == AdvanceEvent.ON_OPENED:
					advanced.emit()
				opened.emit()
			AppearState.CLOSING:
				_close()
				if advance_event == AdvanceEvent.ON_CLOSING:
					advanced.emit()
				if closing.get_connections().size() == 0:
					finish_close.call_deferred()
				else:
					closing.emit()
			AppearState.CLOSED:
				_finish_close()
				closed.emit()
				if advance_event == AdvanceEvent.ON_CLOSED:
					advanced.emit()
				if free_on_closed:
					queue_free()
				else:
					_appear_state = AppearState.READY
					if advance_event == AdvanceEvent.ON_READY:
						advanced.emit()


## Called immediately after instantiation. Use to "populate" the node with specific, one-time information it may need.
func populate(_host: PennyHost, _object: PennyObject = null) -> void:
	host = _host
	object = _object
	_populate(_host, _object)
func _populate(_host: PennyHost, _object: PennyObject) -> void: pass


func _ready() -> void:
	appear_state = AppearState.READY


func open() -> void:
	appear_state = AppearState.OPENING
func _open() -> void: pass


func finish_open() -> void:
	appear_state = AppearState.OPENED
func _finish_open() -> void: pass


func close() -> void:
	appear_state = AppearState.CLOSING
func _close() -> void: pass


func finish_close() -> void:
	appear_state = AppearState.CLOSED
func _finish_close() -> void: pass


func _exit_tree() -> void:
	if object and object.local_instance == self:
		object.clear_instance_upstream()
	if advance_event == AdvanceEvent.ON_EXITING:
		self.advanced.emit()
