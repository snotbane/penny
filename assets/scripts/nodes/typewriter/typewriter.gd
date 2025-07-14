
## Decorator class for a [RichTextLabel]. Prints out text over time in accordance with the Penny script.
class_name Typewriter extends Node

enum PlayState {
	READY,
	PLAYING,
	DELAYED,
	PAUSED,
	COMPLETED
}

static var REGEX_SHAPE_MARKER := RegEx.create_from_string(r"$|(?<=\s)\S")

static var NOW_USEC_FLOAT : float :
	get: return float(Time.get_ticks_usec()) * 0.00_000_1

signal character_arrived(char: String)
signal completed
signal prodded

@export var rtl : RichTextLabel

@export_subgroup("Character Printout")

## If enabled, user prodding will stop at all tags with a prod stop level of [Decor.EProdStop.SOFT] or higher. (This mimics Ren'Py delay tag behavior.)
@export var soft_prod : bool = false

@export var debug_show_shaping_rtl : bool = false

var speed_stack : Array[float] = [ 40.0 ]
## How many characters per second to print out. For specific speeds mid-printout, use the <speed=x> decor.
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

## The maximum height (pixels)
@export_range(0.0, 1080.0, 1.0, "or_greater") var scrollbox_max_height : float
var scrollbox_min_height : float

@export_range(0.0, 1080.0, 1.0, "or_greater") var scrollbox_add_height : float

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

var time_ready : float
var time_reset : float
var time_elapsed : float
var time_per_char : PackedFloat32Array

var tag_opens : Dictionary[int, Array]
var tag_closes : Dictionary[int, Array]

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
			time_per_char[rtl.visible_characters] = NOW_USEC_FLOAT - time_reset
			rtl.visible_characters += increment

			if increment <= 0: continue

			if tag_opens.has(rtl.visible_characters):
				for tag in tag_opens[rtl.visible_characters]:
					tag.encounter_open(self)

			if tag_closes.has(rtl.visible_characters):
				for tag in tag_closes[rtl.visible_characters]:
					tag.encounter_close(self)


		# var last_visible_character_bounds : Rect2 = rtl.last_visible_character_bounds
		# roger.position = last_visible_character_bounds.position

		if message:
			# print(message.visible_text[rtl.visible_characters - 1])
			var shape_marker_match := REGEX_SHAPE_MARKER.search(message.visible_text, rtl.visible_characters)
			shape_rtl.visible_characters = shape_marker_match.get_start() if shape_marker_match else rtl.visible_characters
			if rtl.visible_characters > 0:
				character_arrived.emit(message.visible_text[mini(rtl.visible_characters, message.visible_text.length()) - 1])

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
		for k in tag_opens.keys():
			if visible_characters >= k: continue
			for tag in tag_opens[k]: if tag.is_prod_stop: return k
		return -1


var is_initialized : bool = false
func _ready() -> void:
	install_available_custom_effects()

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

	time_per_char.resize(rtl.get_total_character_count())

	reset()
	is_initialized = true


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

func _process(delta: float) -> void:
	time_elapsed = NOW_USEC_FLOAT - time_reset
	_process_cursor(delta)
	_process_autoscroll(delta)

func _process_cursor(delta: float) -> void:
	if not is_working: return

	if is_typing:
		visible_characters_partial += speed * delta

var user_scroll_override : bool
var last_scroll_y : float
func _process_autoscroll(delta: float) -> void:
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


func _exit_tree() -> void:
	complete()


func reset() -> void:
	shape_rtl.text = rtl.text
	time_reset = NOW_USEC_FLOAT
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

	subject = record.data[&"who"]
	message = record.data[&"what"]

	tag_opens.clear()
	tag_closes.clear()

	rtl.text = message.compile_for_typewriter(self)
	shape_rtl.text = String()
	print(rtl.text)

	time_per_char.resize(rtl.get_total_character_count())
	time_per_char.fill(INF)

	for tag in message.tags:
		register_tag(tag)

	print(tag_opens)

	if not is_initialized: return

	reset()
	present()


func register_tag(tag: Tag) -> void:
	tag.compile_for_typewriter(self)

	if not tag.decor: return

	if tag.decor.has_method(&"encounter_open"):
		if not tag_opens.has(tag.open_index): tag_opens[tag.open_index] = []
		tag_opens[tag.open_index].push_back(tag)

	if tag.decor.has_method(&"encounter_close"):
		if not tag_closes.has(tag.close_index): tag_closes[tag.close_index] = []
		tag_closes[tag.close_index].push_back(tag)

func prod() -> void:
	var is_playing_and_unlocked = is_playing and not is_locked
	prodded.emit()
	if is_playing_and_unlocked:
		visible_characters_partial = next_prod_stop


func delay(seconds: float, new_state: PlayState = PlayState.DELAYED):
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


func install_available_custom_effects() -> void:
	# rtl.install_effect(null)
	# shape_rtl.install_effect(null)
	pass
