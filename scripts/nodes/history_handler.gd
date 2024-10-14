
class_name HistoryHandler extends Control
static var inst : HistoryHandler

@export var animation_player : AnimationPlayer
@export var vbox : VBoxContainer


var _shown : bool = false
var shown : bool = false :
	get: return _shown
	set (value) :
		if _shown == value: return
		_shown = value
		if _shown:
			animation_player.play('show')
		else:
			animation_player.play('hide')

var _verbosity : int
@export_flags(Stmt.VERBOSITY_NAMES[0], Stmt.VERBOSITY_NAMES[1], Stmt.VERBOSITY_NAMES[2], Stmt.VERBOSITY_NAMES[3]) var verbosity : int = Stmt.Verbosity.USER_FACING | Stmt.Verbosity.DEBUG_MESSAGES :
	get: return _verbosity
	set (value):
		if _verbosity == value: return
		_verbosity = value
		for i in controls:
			i.refresh_visibility()

var controls : Array[PennyMessageLabel]

func _ready() -> void:
	inst = self
	visible = shown

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('penny_history'):
		shown = not shown

func receive(rec: Record) -> void:
	var control := PennyMessageLabel.new()
	control.populate(rec)
	controls.push_back(control)
	vbox.add_child(control)

func rewind_to(rec: Record) -> void:
	while controls.size() > rec.stamp:
		var control = controls.pop_back()
		vbox.remove_child(control)
		control.queue_free()
