@tool extends AnimationTree

signal facing_finished

@onready var root_playback : AnimationNodeStateMachinePlayback = self["parameters/blendtree/root/playback"]

var target_facing_state : StringName :
	get: return &"flip_ccw" if _is_facing_right else &"flip_cw"

var _is_facing_right : bool = true
@export var is_facing_right : bool = true :
	get: return _is_facing_right
	set(value):
		if _is_facing_right == value: return
		_is_facing_right = value

		root_playback.travel(target_facing_state)
		wait_for_facing()

func set_is_facing_right(value: bool) -> void:
	is_facing_right = value

func flip_cw() :
	root_playback.play(&"flip_cw")
	await wait_for_facing()

func flip_ccw() :
	root_playback.play(&"flip_ccw")
	await wait_for_facing()

var _is_facing_transition : bool = false
func wait_for_facing() :
	if _is_facing_transition: return

	_is_facing_transition = true
	while true:
		var current_facing_state : StringName = await self.animation_finished
		if target_facing_state == current_facing_state: break
	_is_facing_transition = false

	facing_finished.emit()

