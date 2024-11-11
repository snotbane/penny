
class_name HistoryHandler extends Control
static var inst : HistoryHandler

@export var animation_player : AnimationPlayer
@export var vbox : VBoxContainer

@export var host: PennyHost

@export var _shown : bool = true
var shown : bool :
	get: return _shown
	set (value) :
		if _shown == value: return
		_shown = value
		if _shown:
			animation_player.play('show')
		else:
			animation_player.play('hide')

var _verbosity : int
@export_flags(Stmt.VERBOSITY_NAMES[0], Stmt.VERBOSITY_NAMES[1], Stmt.VERBOSITY_NAMES[2], Stmt.VERBOSITY_NAMES[3], Stmt.VERBOSITY_NAMES[4], Stmt.VERBOSITY_NAMES[5]) var verbosity : int = Stmt.Verbosity.USER_FACING :
	get: return _verbosity
	set (value):
		if _verbosity == value: return
		_verbosity = value
		# for i in controls:
		# 	i.refresh_visibility()

# var controls : Array[PennyMessageLabel]

func _ready() -> void:
	inst = self
	visible = shown


func receive(rec: Record) -> void:
	var listing := rec.create_history_listing()
	vbox.add_child(listing)

func rewind_to(rec: Record) -> void:
	# while controls.size() > rec.stamp:
	# 	var control = controls.pop_back()
		# vbox.remove_child(control)
		# control.queue_free()
	pass


func _on_record_created(record:Record) -> void:
	receive(record)


func _on_verbosity_selector_item_selected(index:int) -> void:
	self.verbosity = index
