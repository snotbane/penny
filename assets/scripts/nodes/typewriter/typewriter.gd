
## Decorator class for a [RichTextLabel]. Prints out text over time in accordance with the Penny script.
class_name Typewriter extends Node

enum PlayState {
	READY,
	PLAYING,
	DELAYED,
	PAUSED,
	COMPLETED
}

signal character_arrived(char: String)
signal completed
signal prodded

@export var rtl : RichTextLabel

@export_subgroup("Character Printout")

## If enabled, delays will be treated like wait tags in that when we try to prod the typewriter to continue, we will stop at both delays and waits. (This mimics Ren'Py behavior.)
@export var treat_delay_as_wait : bool = false

var speed_stack : Array[float] = [ 40.0 ]
## How many characters per second to print out. For specific speeds mid-printout, use the <speed=x> decoration.
@export var print_speed : float = 40.0 :
	get: return speed_stack[0]
	set(value):
		speed_stack[0] = value

@export_subgroup("Audio")

var _audio_player : TypewriterAudioStreamPlayer
@export var audio_player : TypewriterAudioStreamPlayer :
	get: return _audio_player
	set(value):
		if _audio_player == value: return

		if _audio_player:
			character_arrived.disconnect(_audio_player.receive_character)

		_audio_player = value

		if _audio_player:
			character_arrived.connect(_audio_player.receive_character)


@export_subgroup("Autoscroll")

@export var scroll_container : ScrollContainer

var user_scroll_enabled : bool = true :
	get:
		if not scroll_container: return false
		return scroll_container.mouse_filter != Control.MOUSE_FILTER_IGNORE
	set(value):
		if not scroll_container: return
		if user_scroll_enabled == value: return
		scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS if value else Control.MOUSE_FILTER_IGNORE
		v_scroll_bar.mouse_filter = scroll_container.mouse_filter

		user_scroll_override = false

## Speed at which [member scroll_container] scrolls/grows automatically.
@export var autoscroll_speed : float = 12.0

## The maximum height (pixels)
@export_range(0.0, 1080.0, 1.0, "or_greater") var scrollbox_max_height : float
var scrollbox_min_height : float

@export_range(0.0, 1080.0, 1.0, "or_greater") var scrollbox_add_height : float


@export_subgroup("Roger")

## Also known as "click to continue" or "CTC". This is the [CanvasItem] which represents that.
@export var roger : CanvasItem

## If enabled, the roger will always appear when the user must prod the dialog to continue. Otherwise, it will appear only when the entire text printout is completed.
@export var roger_appears_on_paused := false

var _play_state := PlayState.READY
var play_state : PlayState :
	get: return _play_state
	set(value):
		if _play_state == value: return
		_play_state = value

		user_scroll_enabled = _play_state == PlayState.PAUSED or _play_state == PlayState.COMPLETED
		is_talking = _play_state == PlayState.PLAYING

		match _play_state:
			PlayState.READY, PlayState.COMPLETED:
				_visible_characters_partial = 0
				is_locked = false
				user_scroll_override = false

		if roger:
			match _play_state:
				PlayState.PAUSED:		roger.visible = roger_appears_on_paused
				PlayState.COMPLETED:	roger.visible = true
				_:						roger.visible = false

var is_locked : bool = false
var is_typing : bool :
	get: return play_state == PlayState.PLAYING
var is_playing : bool :
	get: return play_state == PlayState.PLAYING or play_state == PlayState.DELAYED

var shape_rtl : RichTextLabel
var v_scroll_bar : VScrollBar

var subject : Cell
var message : DisplayString

var deco_starts : Dictionary[int, Array]
var deco_ends : Dictionary[int, Array]

var _visible_characters_partial : float
var visible_characters_partial : float :
	get: return _visible_characters_partial
	set(value):
		_visible_characters_partial = value
		visible_characters = floori(value)


var visible_characters : int :
	get: return rtl.visible_characters
	set (value):
		value = clampi(value, -1, rtl.get_total_character_count())
		if rtl.visible_characters == value: return

		var increment := 1 if value == -1 else signi(value - rtl.visible_characters)
		var target := rtl.get_total_character_count() if value == -1 else value
		while rtl.visible_characters != target:
			rtl.visible_characters += increment
			shape_rtl.visible_characters = rtl.visible_characters

			if deco_starts.has(rtl.visible_characters):
				for deco_start in deco_starts[rtl.visible_characters]:
					deco_start.encounter_start(self)

			if deco_ends.has(rtl.visible_characters):
				for deco_end in deco_ends[rtl.visible_characters]:
					deco_end.encounter_end(self)

		# var last_visible_character_bounds : Rect2 = rtl.last_visible_character_bounds
		# roger.position = last_visible_character_bounds.position

		if message and rtl.visible_characters > 0:
			character_arrived.emit(message.visible_text[rtl.visible_characters - 1])
			# print(message.visible_text[rtl.visible_characters - 1])

		if rtl.visible_characters == rtl.get_total_character_count():
			rtl.visible_characters = -1
		else:
			_visible_characters_partial = rtl.visible_characters + fmod(_visible_characters_partial, 1.0)

		if rtl.visible_characters == -1:
			play_state = PlayState.COMPLETED
			completed.emit()

var speed : float :
	get: return self.speed_stack.back()


var is_working : bool :
	get: return visible_characters != -1


var _is_talking : bool
##
var is_talking : bool :
	get: return _is_talking
	set(value):
		if _is_talking == value: return
		_is_talking = value

		if subject == null or subject.instance == null or not subject.instance.has_method(&"set_is_talking"): return

		subject.instance.set_is_talking(_is_talking)


var next_prod_stop : int :
	get:
		for k in deco_starts.keys():
			if visible_characters >= k: continue
			for deco in deco_starts[k]:	if deco_is_prod_stop(deco):	return k
		return -1


var is_initialized : bool = false
func _ready() -> void:
	v_scroll_bar = scroll_container.get_v_scroll_bar()
	scrollbox_min_height = scroll_container.custom_minimum_size.y

	## Set up the fake rtl to ensure proper scrolling limits
	shape_rtl = rtl.duplicate()
	shape_rtl.name = "%s (shape)" % rtl.name
	shape_rtl.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	shape_rtl.visibility_layer = 0
	shape_rtl.focus_mode = Control.FOCUS_NONE

	rtl.add_sibling.call_deferred(shape_rtl)

	reset()
	is_initialized = true


func _process(delta: float) -> void:
	_process_cursor(delta)
	_process_autoscroll(delta)

func _process_cursor(delta: float) -> void:
	if not is_working: return

	if is_typing:
		visible_characters_partial += speed * delta

var user_scroll_override : bool
var last_scroll_y : float
func _process_autoscroll(delta: float) -> void:
	if not scroll_container: return

	var target_height := shape_rtl.get_content_height() + scrollbox_add_height
	target_height = maxf(target_height, scrollbox_min_height)
	if scrollbox_max_height > 0.0:
		target_height = minf(target_height, scrollbox_max_height)

	var maximum_height_reached := target_height == scrollbox_max_height
	var max_scroll_y := (shape_rtl.get_content_height() - scroll_container.size.y) + (scrollbox_add_height / (1.0 if maximum_height_reached else 2.0))

	scroll_container.custom_minimum_size = lerp(
		scroll_container.custom_minimum_size,
		Vector2(
			scroll_container.custom_minimum_size.x,
			target_height
		),
		autoscroll_speed * delta
	)

	v_scroll_bar.value = minf(v_scroll_bar.value, max_scroll_y)

	user_scroll_override = user_scroll_enabled and v_scroll_bar.value < (max_scroll_y if user_scroll_override else last_scroll_y)

	if not user_scroll_override:
		v_scroll_bar.value = lerp(
			v_scroll_bar.value,
			max_scroll_y,
			(autoscroll_speed * delta) if maximum_height_reached else 1.0
		)
		last_scroll_y = v_scroll_bar.value


func _exit_tree() -> void:
	complete()


func reset() -> void:
	shape_rtl.text = rtl.text
	play_state = PlayState.READY
	visible_characters_partial = 0


func present() -> void:
	visible_characters_partial = 0
	await get_tree().create_timer(0.5).timeout
	play_state = PlayState.PLAYING


func complete() -> void:
	visible_characters = -1


func receive(record: Record) -> void: _receive(record)
func _receive(record: Record) -> void:
	complete()

	subject = record.data["who"]
	message = record.data["what"]

	rtl.text = message.text
	shape_rtl.text = String()

	deco_starts.clear()
	deco_ends.clear()
	for deco in message.decos:
		deco.create_remap_for(self)

		if not deco_starts.has(deco.start_remapped): deco_starts[deco.start_remapped] = []
		deco_starts[deco.start_remapped].push_back(deco)

		if not deco_ends.has(deco.end_remapped): deco_ends[deco.end_remapped] = []
		deco_ends[deco.end_remapped].push_back(deco)

	if not is_initialized: return

	reset()
	present()


func prod() -> void:
	var is_playing_and_unlocked = is_playing and not is_locked
	prodded.emit()
	if is_playing_and_unlocked:
		visible_characters_partial = next_prod_stop


func deco_is_prod_stop(deco: DecoInst) -> bool:
	return deco.template is DecoWait or deco.template is DecoLock or (treat_delay_as_wait and deco.template is DecoDelay)



func delay(seconds: float):
	var new_state : PlayState = PlayState.PAUSED if treat_delay_as_wait else PlayState.DELAYED
	play_state = new_state
	await get_tree().create_timer(seconds).timeout
	if play_state == new_state: play_state = PlayState.PLAYING


func wait():
	play_state = PlayState.PAUSED
	await prodded
	play_state = PlayState.PLAYING


func push_speed_tag(characters_per_second: float) -> void:
	speed_stack.push_back(characters_per_second)

func pop_speed_tag() -> void:
	if speed_stack.size() <= 1: return
	speed_stack.pop_back()
