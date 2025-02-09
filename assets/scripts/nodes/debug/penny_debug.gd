
class_name PennyDebug extends Control

static var inst : PennyDebug
var host : PennyHost

signal host_changed(host: PennyHost)
signal host_changed_unbound
signal on_reload_start
signal on_reload_finish(success: bool)
signal on_reload_cancel


func _ready() -> void:
	inst = self
	$overlay.visible = false

	if PennyHost.insts:
		set_active_host(PennyHost.insts.front())


func _input(event: InputEvent) -> void:
	# if not OS.is_debug_build(): return
	if event.is_action_pressed("penny_debug"):
		$overlay.visible = not $overlay.visible


func set_active_host(_host: PennyHost) -> void:
	host = _host
	host_changed.emit(_host)
	host_changed_unbound.emit()
