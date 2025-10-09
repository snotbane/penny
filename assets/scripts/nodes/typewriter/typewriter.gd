
## Decorator class for a [RichTextLabel]. Prints out text over time in accordance with the Penny script.
class_name Typewriter extends Node

#region Static

enum PlayState {
	RESETTING,
	READY,
	PLAYING,
	DELAYED,
	PAUSED,
	COMPLETED,
}

static var REGEX_SHAPE_MARKER := RegEx.create_from_string(r"$|(?<=\s)\S")

static var now : float

static var user_setting_print_speed : float = 1.0

static var NOW_USEC_FLOAT : float :
	get: return float(Time.get_ticks_usec()) * 0.00_000_1

#endregion

#region Exposures

signal character_arrived(char: String)
signal visible_message_changed
signal received(record: Record)
signal advanced
signal completed
signal prodded
signal roger_shown(visible: bool)

@export var rtl : RichTextLabel

var speed_stack : Array[float] = [ 40.0 ]
## How many characters per second to print out. For specific speeds mid-printout, use the <speed=x> decor.
@export var print_speed : float = 40.0 :
	get: return speed_stack[0]
	set(value):
		speed_stack[0] = value
var speed : float :
	get: return user_setting_print_speed * speed_stack.back()

var volume_stack : Array[float] = [ 1.0 ]
## How loud (percentage of the currently active [AudioStreamPlayer]) to play voice audio. For specific volume mid-printout, use the <volume=x> decor.
@export var print_volume : float = 1.0 :
	get: return volume_stack[0]
	set(value):
		volume_stack[0] = value
var volume : float :
	get: return volume_stack.back()

## Amount of time to wait after receiving a new message, before printing it out.
@export var start_delay : float = 0.5
## When a completed message already exists, amount of time to wait before replacing the existing text.
@export var reset_delay : float = 0.5

@export_subgroup("Autoscroll")

@export var scroll_container : ScrollContainer

## The maximum height (pixels)
@export_range(0.0, 1080.0, 1.0, "or_greater") var scrollbox_max_height : float
var scrollbox_min_height : float

@export_range(0.0, 1080.0, 1.0, "or_greater") var scrollbox_add_height : float

## Curve used to define autoscroll speed. X is the distance (positive or negative) that the scrollbox must travel/resize. Y is the speed (positive only) at which it will travel/resize.
@export var autoscroll_curve : Curve

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
@export var autoscroll_multiplier : float = 1.0

@export_subgroup("Roger")

## Also known as "click to continue" or "CTC". This is the [CanvasItem] which represents that.
@export var roger : CanvasItem

@export_subgroup("Audio")

var _talker_volume_default : float
var _talker_audio_player_default : TypewriterAudioStreamPlayer
var _talker_audio_player : TypewriterAudioStreamPlayer
@export var talker_audio_player : TypewriterAudioStreamPlayer :
	get: return _talker_audio_player
	set(value):
		if value == null: value = _talker_audio_player_default
		if _talker_audio_player == value: return

		if _talker_audio_player:
			_talker_audio_player.volume_linear = _talker_volume_default
			character_arrived.disconnect(_talker_audio_player.receive_character)

		_talker_audio_player = value

		if _talker_audio_player:
			_talker_volume_default = _talker_audio_player.volume_linear
			character_arrived.connect(_talker_audio_player.receive_character)

		refresh_volume()

@export_subgroup("Debug")

@export var debug_show_shaping_rtl : bool = false

#endregion
#region Pinions

var is_locked : bool = false
var is_typing : bool :
	get: return play_state == PlayState.PLAYING and not visible_characters_completed
var is_playing : bool :
	get: return play_state == PlayState.PLAYING or play_state == PlayState.DELAYED
var is_working : bool :
	get: return play_state != PlayState.COMPLETED

var shape_rtl : RichTextLabel
var v_scroll_bar : VScrollBar

var _subject : Cell
var subject : Cell :
	get: return _subject
	set(value):
		if _subject == value: return
		_subject = value

		if _subject:
			var inst := _subject.instance
			talker_audio_player = inst.voice_audio_player if (inst and inst is SpriteActor3D and inst.voice_audio_player) else null
		else:
			talker_audio_player = null

var _message : DisplayString
var message : DisplayString :
	get: return _message
	set(value):
		if _message == value: return
		_message = value
		visible_message_changed.emit()

var visible_characters_max : int
var time_reseted : float = INF
var time_prepped : float
var time_elapsed : float
var time_per_char : PackedFloat32Array

var element_opens : Dictionary[int, Array]
var element_closes : Dictionary[int, Array]

#endregion
#region Properties

var _play_state := PlayState.READY
var play_state := PlayState.READY :
	get: return _play_state
	set(value):
		if _play_state == value: return
		_play_state = value

		user_scroll_enabled = _play_state == PlayState.PAUSED or _play_state == PlayState.COMPLETED

		roger_shown.emit(play_state == PlayState.COMPLETED)

		match _play_state:
			PlayState.READY, PlayState.COMPLETED:
				_visible_characters_partial = 0
				is_locked = false
				user_scroll_override = false
				is_talking = false

		match _play_state:
			PlayState.READY:
				time_reseted = INF
			PlayState.RESETTING:
				time_reseted = Typewriter.now
			PlayState.COMPLETED:
				completed.emit()

var _is_talking : bool
var is_talking : bool :
	get: return _is_talking
	set(value):
		if _is_talking == value: return
		_is_talking = value

		if subject == null or subject.instance == null or not subject.instance.has_method(&"set_is_talking"): return

		subject.instance.set_is_talking(_is_talking)

var next_prod_stop : int :
	get:
		if visible_characters_completed: return visible_characters_max
		for k in element_opens.keys():
			if visible_characters >= k: continue
			for element in element_opens[k]: if element.prod_stop: return k
		return visible_characters_max

var _visible_characters_partial : float
var visible_characters_partial : float :
	get: return _visible_characters_partial
	set(value):
		_visible_characters_partial = value
		visible_characters = floori(value)

var visible_characters_completed : bool :
	get: return visible_characters == visible_characters_max

var visible_characters : int :
	get: return rtl.visible_characters
	set (value):
		value = clampi(value, 0, visible_characters_max)
		if rtl.visible_characters == value: return

		var increment := signi(value - rtl.visible_characters)
		while rtl.visible_characters != value:
			time_per_char[rtl.visible_characters] = time_elapsed
			rtl.visible_characters += increment

			if increment <= 0: continue

			handle_elements()

		# var last_visible_character_bounds : Rect2 = rtl.last_visible_character_bounds
		# roger.position = last_visible_character_bounds.position

		if message:
			# print(message.visible_text[rtl.visible_characters - 1])
			var shape_marker_match := REGEX_SHAPE_MARKER.search(message.visible_text, rtl.visible_characters)
			shape_rtl.visible_characters = shape_marker_match.get_start() if shape_marker_match else rtl.visible_characters
			if rtl.visible_characters > 0:
				encounter_char(message.visible_text[mini(rtl.visible_characters, message.visible_text.length()) - 1])

		if not visible_characters_completed:
			_visible_characters_partial = rtl.visible_characters + fmod(_visible_characters_partial, 1.0)

		visible_message_changed.emit()


var handling_elements : bool
func handle_elements() -> void:
	handling_elements = true

	if element_opens.has(rtl.visible_characters):
		for element in element_opens[rtl.visible_characters]:
			if element.prod_stop:	await	element.encounter_open()
			else:							element.encounter_open()

	if element_closes.has(rtl.visible_characters):
		for element in element_closes[rtl.visible_characters]:
			if element.prod_stop:	await	element.encounter_close()
			else:							element.encounter_close()

	handling_elements = false

#endregion

#region _ready(), _exit_tree()

var is_initialized : bool = false
func _ready() -> void:
	if scroll_container:
		v_scroll_bar = scroll_container.get_v_scroll_bar()
		scrollbox_min_height = scroll_container.custom_minimum_size.y

	## Set up the fake rtl to ensure proper scrolling limits
	shape_rtl = rtl.duplicate()
	shape_rtl.name = "%s (shape)" % rtl.name
	shape_rtl.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	shape_rtl.visibility_layer = 1 if debug_show_shaping_rtl and OS.is_debug_build() else 0
	shape_rtl.self_modulate = Color(1, 0, 0)
	shape_rtl.focus_mode = Control.FOCUS_NONE

	rtl.add_sibling.call_deferred(shape_rtl)
	rtl.get_parent().move_child.call_deferred(shape_rtl, 0)

	time_per_char.resize(visible_characters_max + 1)

	roger.set.call_deferred(&"visible", false)

	_talker_audio_player_default = _talker_audio_player

	prep()
	is_initialized = true


func _exit_tree() -> void:
	reset()

#endregion
#region _input()

var user_did_scroll_input : bool = false
func _input(event: InputEvent) -> void:
	if event is InputEventPanGesture:
		user_did_scroll_input = event.delta.y != 0.0
	elif Input.get_axis(&"penny_scroll_up", &"penny_scroll_down") != 0.0:
		user_did_scroll_input = true
	elif OS.is_debug_build() and event is InputEventKey:
		if not event.is_pressed(): return
		if event.physical_keycode == KEY_PERIOD:
			visible_characters += 1
		elif event.physical_keycode == KEY_COMMA:
			visible_characters -= 1

#endregion
#region _process()

func _process(delta: float) -> void:
	now = float(Time.get_ticks_usec()) * 0.00_000_1
	time_elapsed = now - time_prepped

	_process_cursor(delta)
	_process_autoscroll(delta)
	_process_end(delta)


func _process_cursor(delta: float) -> void:
	if not is_typing: return

	visible_characters_partial += speed * delta


var user_scroll_override : bool
var last_scroll_y : float
func _process_autoscroll(delta: float) -> void:
	if not scroll_container: return

	var is_maximum_height_reached := scroll_container.custom_minimum_size.y >= scrollbox_max_height if scrollbox_max_height > 0.0 else false

	var target_height := shape_rtl.get_content_height() + scrollbox_add_height
	target_height = maxf(target_height, scrollbox_min_height)
	if scrollbox_max_height > 0.0:
		target_height = minf(target_height, scrollbox_max_height)

	var max_scroll_y := (shape_rtl.get_content_height() - target_height) + (scrollbox_add_height / (1.0 if is_maximum_height_reached else 2.0))

	var motion := (target_height - scroll_container.custom_minimum_size.y) + maxf(max_scroll_y - v_scroll_bar.value, 0.0)
	var alpha := autoscroll_curve.sample(motion) * autoscroll_multiplier * delta

	scroll_container.custom_minimum_size.y = move_toward(
		scroll_container.custom_minimum_size.y,
		target_height,
		alpha
	)

	v_scroll_bar.value = minf(v_scroll_bar.value, max_scroll_y)
	user_scroll_override = user_scroll_enabled and v_scroll_bar.value < (max_scroll_y if user_scroll_override else last_scroll_y) and (user_scroll_override or user_did_scroll_input)

	if is_maximum_height_reached and not user_scroll_override:
		v_scroll_bar.value = move_toward(
			v_scroll_bar.value,
			max_scroll_y,
			alpha
		)
		last_scroll_y = v_scroll_bar.value


func _process_end(delta: float) -> void:
	if play_state == PlayState.COMPLETED or not visible_characters_completed: return

	if handling_elements: return

	for k in element_opens: for element in element_opens[k]:
		if element.encounter_state < DecorElement.CLOSED: return

	play_state = PlayState.COMPLETED


#endregion

#region Script Functions

func clear() -> void:
	rtl.visible_characters = 0
	_visible_characters_partial = 0

## Preps the dialog for printout, but doesn't start.
func prep() -> void:
	shape_rtl.text = rtl.text
	time_prepped = NOW_USEC_FLOAT
	play_state = PlayState.READY
	clear()

## Begins printout.
func present() -> void:
	clear()
	await get_tree().create_timer(start_delay).timeout
	play_state = PlayState.PLAYING

## Skips to the very end, but doesn't reset.
func complete() -> void:
	visible_characters = visible_characters_max
	play_state = PlayState.COMPLETED

## Resets the dialog to be used again.
func reset():
	clear()
	play_state = PlayState.RESETTING
	await get_tree().create_timer(reset_delay).timeout
	play_state = PlayState.READY


func receive(record: Record) : _receive(record)
func _receive(record: Record) :
	if play_state != PlayState.READY:
		await reset()

	subject = record.data[&"who"].evaluate()
	message = record.data[&"what"]

	element_opens.clear()
	element_closes.clear()

	rtl.text = message.compile_for_typewriter(self)
	shape_rtl.text = String()

	visible_characters_max = rtl.get_total_character_count()
	assert(visible_characters_max == message.visible_text.length(), "The DisplayString's calculated length is different from its actual length! This usually happens because there is an unrecognized BBcode somewhere in the text:\n'%s'" % rtl.text)

	time_per_char.resize(visible_characters_max)
	time_per_char.fill(INF)

	var visible_offset := 0
	for element in message.elements:
		var compile_result := element.compile_for_typewriter(self)
		visible_offset += compile_result.length()

		if not element.decor: continue

		if element.decor.has_method(&"encounter_open"):
			if not element_opens.has(element.open_index): element_opens[element.open_index + visible_offset] = []
			element_opens[element.open_index + visible_offset].push_back(element)

		if element.decor.has_method(&"encounter_close"):
			if not element_closes.has(element.close_index): element_closes[element.close_index + visible_offset] = []
			element_closes[element.close_index + visible_offset].push_back(element)

	received.emit(record)

	if not is_initialized: return

	prep()
	present()


func prod() -> void:
	var is_playing_and_unlocked = is_playing and not is_locked
	prodded.emit()
	if is_playing_and_unlocked:
		visible_characters_partial = next_prod_stop


func advance() -> void:
	complete()
	advanced.emit()

#endregion
#region Event Functions

@export var talk_character_pattern : String
@export var silent_character_pattern : String

@onready var talk_character_regex := RegEx.create_from_string(talk_character_pattern)
@onready var silent_character_regex := RegEx.create_from_string(silent_character_pattern)

func encounter_char(c: String) -> void:
	character_arrived.emit(c)

	if silent_character_regex.search(c):
		is_talking = false
	elif talk_character_regex.search(c):
		is_talking = true

#endregion
#region DecorElement Functions

func install_effect_from(element: DecorElement) -> void:
	if not element.decor.effect: return
	if rtl.custom_effects.has(element.decor.effect): return

	rtl.install_effect(element.decor.effect)
	# Definitely necessary even though it's invisible. If disabled, multiple lines/scrolling may be broken.
	shape_rtl.install_effect(element.decor.effect)


func delay(seconds: float, new_state: PlayState = PlayState.DELAYED) :
	play_state = new_state
	await Async.any([get_tree().create_timer(seconds).timeout, prodded])
	if play_state == new_state: play_state = PlayState.PLAYING


func wait(show_roger := false) :
	play_state = PlayState.PAUSED
	roger_shown.emit(show_roger)
	await prodded
	play_state = PlayState.PLAYING
	roger_shown.emit(false)


func push_speed_element(characters_per_second: float) -> void:
	speed_stack.push_back(characters_per_second)

func pop_speed_element() -> void:
	if speed_stack.size() <= 1: return
	speed_stack.pop_back()


func push_volume_element(volume_percent: float) -> void:
	volume_stack.push_back(volume_percent)
	refresh_volume()

func pop_volume_element() -> void:
	if volume_stack.size() <= 1: return
	volume_stack.pop_back()
	refresh_volume()

func refresh_volume() -> void:
	if not talker_audio_player: return

	talker_audio_player.volume_linear = _talker_volume_default * volume


func play_sfx(stream: AudioStream, from: Cell, wait_to_complete: bool = true, wait_state : PlayState = PlayState.DELAYED) :
	var audio_player : AudioStreamPlayer = from.instance

	audio_player.stream = stream
	audio_player.play()
	if wait_to_complete:
		play_state = wait_state
		await Async.any([audio_player.finished, prodded])
		play_state = PlayState.PLAYING

#endregion
