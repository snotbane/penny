
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
	ON_OPEN,
	## Triggers after [member opened]
	ON_PRESENT,
	## Triggers when [member close] starts.
	ON_CLOSING,
	## Triggers after [member close] finishes.
	ON_CLOSED,
	## Triggers on [member tree_exiting]
	ON_EXITING,
	## Does not trigger on any predefined event; instead leaves it to the user to define when [member advanced] is emitted.
	CUSTOM,
}

## Emitted when this node is given the clear to transition from [member _ready] to [member _present]
signal opening
signal opened
signal closing
signal closed
signal advanced

@export var advance_event := AdvanceEvent.ON_READY

## If enabled, this node will immediately open (visually) on ready.
@export var open_on_ready  : bool = true

## If enabled, this node will immediately [member close] when its owning object instantiates a new instance of any link.
@export var close_on_unlinked : bool = false

## If enabled, this node will immediately [member queue_free] when it is [member close]d.
@export var free_on_closed : bool = false


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
				if advance_event == AdvanceEvent.ON_READY:
					advanced.emit()
			AppearState.OPENING:
				_open()
				opening.emit()
				if advance_event == AdvanceEvent.ON_OPEN:
					advanced.emit()
			AppearState.OPENED:
				_present()
				opened.emit()
				if advance_event == AdvanceEvent.ON_PRESENT:
					advanced.emit()
			AppearState.CLOSING:
				_close()
				closing.emit()
				if advance_event == AdvanceEvent.ON_CLOSING:
					advanced.emit()
			AppearState.CLOSED:
				_appear_state = AppearState.READY
				_finish_close()
				closed.emit()
				if advance_event == AdvanceEvent.ON_READY:
					advanced.emit()
				if free_on_closed:
					queue_free()


## Called immediately after instantiation. Use to "populate" the node with specific, one-time information it may need.
func populate(_host: PennyHost, _object: PennyObject = null) -> void:
	advanced.connect(print.bind("Advanced Penny Node"))
	host = _host
	object = _object
	_populate(_host, _object)
func _populate(_host: PennyHost, _object: PennyObject) -> void: pass


func _ready() -> void:
	appear_state = AppearState.READY


func open() -> void:
	appear_state = AppearState.OPENING
func _open() -> void: pass


func present() -> void:
	appear_state = AppearState.OPENED
func _present() -> void: pass


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
