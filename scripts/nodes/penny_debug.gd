
class_name PennyDebug extends Control

static var inst : PennyDebug

signal on_host_changed(host: PennyHost)
signal on_reload_start
signal on_reload_finish(success: bool)
signal on_reload_cancel

var _host: PennyHost
var host : PennyHost :
	get: return _host
	set(value):
		_host = value
		on_host_changed.emit(_host)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	inst = self
	if PennyHost.insts:
		host = PennyHost.insts[0]

	$overlay.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	# if not OS.is_debug_build(): return
	if event.is_action_pressed('penny_history'):
		if $overlay.visible:
			$overlay.visible = false
	if event.is_action_pressed('penny_debug'):
		$overlay.visible = not $overlay.visible
