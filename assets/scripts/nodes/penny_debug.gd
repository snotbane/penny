
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

	if PennyHost.insts:
		set_active_host(PennyHost.insts.front())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("penny_debug"):
		if $debug_panel_window.visible:
			$debug_panel_window.hide()
		else:
			$debug_panel_window.popup()


func set_active_host(_host: PennyHost) -> void:
	host = _host
	host_changed.emit(_host)
	host_changed_unbound.emit()
