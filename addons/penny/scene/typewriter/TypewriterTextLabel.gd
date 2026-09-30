## Text box specifically designed to print out text over time. Works with unique Penny decorations.
class_name TypewriterTextLabel
extends RichTextLabel

enum {
	READY,
	PLAYING,
	FINISHED,
	RESETTING,
}


signal advanced
signal poked

var _poke_source_fallback: Control

## When this node is clicked, it will poke the typewriter. If unset, an internal Control covering the entire screen will be used..
@export
var poke_source: Control:
	set(value):
		if value == null:
			value = _poke_source_fallback

		if poke_source:
			poke_source.gui_input.disconnect(_gui_input_click_poke)

		poke_source = value

		_poke_source_fallback.visible = poke_source == _poke_source_fallback

		if poke_source:
			poke_source.gui_input.connect(_gui_input_click_poke)

func _gui_input_click_poke(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			poke()

var poke_lock: int = 0:
	set(value):
		poke_lock = maxi(value, 0)


## Initiates a user poke. You can call this method to add your own custom functionality. Use a <lock> decoration to prevent this functionality while typing.
func poke() -> void:
	match state:
		PLAYING:
			if poke_lock == 0:
				set_visible_characters_partial(get_next_poke_stop(), false)
			poked.emit()

		FINISHED:
			advance()


func get_next_poke_stop() -> int:
	if state < PLAYING:
		return 0
	elif state > PLAYING:
		return -1

	for k in source_tags:
		if k <= visible_characters:
			continue

		for tag: Penny.Text.Tag in source_tags[k]:
			for inst in tag:
				if inst.template.get_poke_stop():
					return k

	return -1

var _sfx_audio_player_default: AudioStreamPlayer

## The default [AudioStreamPlayer] to use for sfx tags. If unset, a default [AudioStreamPlayer] will be used. This node is not used if <sfx=
@export
var sfx_audio_player: Node


var present_delay_timer: Timer
## The amount of time to wait before presenting text.
@export_range(0.0, 1.0, 0.01, "or_greater")
var present_delay: float = 0.5:
	set(value):
		present_delay = value

		if present_delay > 0.1:
			present_delay_timer.wait_time = value


var reset_delay_timer: Timer
## The minimum amount of time to wait to reset the text. If you have any special decorations that function after reset, this duration should account for that.
@export_range(0.0, 1.0, 0.01, "or_greater")
var reset_delay: float = 0.5:
	set(value):
		reset_delay = value

		if reset_delay > 0.1:
			reset_delay_timer.wait_time = value



static var rate_base: float:
	get: return ProjectSettings.get_setting("penny/typewriter/rate_base", 100.0)
	set(value): ProjectSettings.set_setting("penny/typewriter/rate_base", value)

var rate_stack: PackedFloat32Array

var speed_stack: PackedFloat32Array

var speed_percent: float:
	get: return speed_stack[-1] if speed_stack else 1.0

var typing_rate_and_speed: float:
	get:
		var rate: float = rate_stack[-1] if rate_stack else rate_base
		return rate * speed_percent


var delay_timer: Timer


signal playing_changed
signal state_changed
var state: int = READY:
	set(value):
		if state == value: return

		if state == PLAYING or value == PLAYING:
			playing_changed.emit()

		state = value

		match state:
			PLAYING:
				time_started_stamp = Time.get_ticks_usec()
				time_reseted_stamp = INT64_MAX

			FINISHED:
				poke_lock = 0
				rate_stack.clear()
				speed_stack.clear()

			RESETTING:
				time_reseted_stamp = Time.get_ticks_usec()

		if state != PLAYING:
			pausing = false

		state_changed.emit()


signal pausing_changed
var pausing: bool = false:
	set(value):
		if pausing == value: return

		pausing = value
		pausing_changed.emit()


var typing: bool:
	get: return state == PLAYING and not pausing


var source: Variant:
	set(value):
		source = value

		if source is Penny.Text:
			source_text = source.text
			source_tags = source.tags.get_indexed_dict()
		else:
			source_text = value
			source_tags = {}

		visible_characters_max = get_total_character_count()
		characters_time_stamps.resize(visible_characters_max + 1)
		characters_time_stamps.fill(INF)


var object_context

var source_text: String
var source_tags: Dictionary


var visible_characters_max: int

var visible_characters_partial: float = 0.0


var time_started_stamp: int
var time_elapsed_stamp: int
var time_reseted_stamp: int
var characters_time_stamps: PackedInt32Array


# ## Internal, invisible copy of this label which prints the same text out, word-by-word, to determine the appropriate height of the control.
# var shaper: RichTextLabel


func _init() -> void:
	_poke_source_fallback = Control.new()
	_poke_source_fallback.name = &"_poke_source_fallback"
	_poke_source_fallback.show_behind_parent = true
	_poke_source_fallback.top_level = true
	_poke_source_fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_poke_source_fallback, false, INTERNAL_MODE_BACK)

	_sfx_audio_player_default = AudioStreamPlayer.new()
	add_child(_sfx_audio_player_default)

	present_delay_timer = Timer.new()
	present_delay_timer.autostart = false
	present_delay_timer.one_shot = true
	present_delay_timer.wait_time = 0.5
	add_child(present_delay_timer)

	reset_delay_timer = Timer.new()
	reset_delay_timer.autostart = false
	reset_delay_timer.one_shot = true
	reset_delay_timer.wait_time = 0.5
	add_child(reset_delay_timer)

	delay_timer = Timer.new()
	delay_timer.autostart = false
	delay_timer.one_shot = true
	add_child(delay_timer)


# 	shaper = duplicate(0)
# 	shaper.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
# 	add_child(shaper)


func _ready() -> void:
	if poke_source == null:
		poke_source = _poke_source_fallback

	if sfx_audio_player == null:
		sfx_audio_player = _sfx_audio_player_default

	visible_characters = 0

	# visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING


var processing = null
func _process(delta: float) -> void:
	time_elapsed_stamp = Time.get_ticks_usec() - time_started_stamp

	if typing and processing != source:
		processing = source
		await add_visible_characters_partial(typing_rate_and_speed * delta)
		processing = null


func present(__source__, __object_context__):
	assert(state == READY)

	source = __source__
	object_context = __object_context__
	state = PLAYING
	pausing = true

	_start_sequence()

	await advanced

	assert(state == FINISHED)
	await reset()


func _start_sequence() -> void:
	var current_source = source

	visible_characters_partial = 0.0
	visible_characters = 0

	if present_delay > 0.1:
		present_delay_timer.start()
		await present_delay_timer.timeout

	if state != PLAYING or current_source != source:
		return

	await _handle_elements()

	if state != PLAYING or current_source != source:
		return

	pausing = false


## Completes the text if it is currently playing.
func complete() -> void:
	if state >= FINISHED:
		return

	set_visible_characters_partial(-1, false)


func reset():
	state = RESETTING

	reset_delay_timer.start()
	await reset_delay_timer.timeout

	visible_characters_partial = 0.0
	visible_characters = 0

	await get_tree().process_frame

	state = READY


## Forces the typewriter to be marked as complete.
func advance() -> void:
	if state < FINISHED:
		state = FINISHED
	advanced.emit()


func add_visible_characters_partial(value: float):
	await set_visible_characters_partial(visible_characters_partial + value)

func set_visible_characters_partial(value: float, wait: bool = true):
	visible_characters_partial = value

	if visible_characters_partial < 0:
		visible_characters = visible_characters_max
		visible_characters_partial = visible_characters_max
		# for i in characters_time_stamps.size():
		# 	characters_time_stamps[i] = minf(characters_time_stamps[i], time_elapsed_stamp)
		# state = FINISHED
		# return

	var visible_characters_target := clampi(floori(visible_characters_partial), 0, visible_characters_max)

	var inc := signi(visible_characters_target - visible_characters)
	if inc == 0:
		return

	while visible_characters != visible_characters_target:
		characters_time_stamps[visible_characters] = time_elapsed_stamp
		visible_characters += inc

		if inc < 0:
			continue

		await _handle_elements(wait)

	visible_characters_partial = float(visible_characters) + fmod(visible_characters_target, 1.0)

	if visible_characters == visible_characters_max:
		state = FINISHED


func _handle_elements(wait: bool = true):
	if state != PLAYING:
		return

	if not source_tags.has(visible_characters):
		return

	for tag: Penny.Text.Tag in source_tags[visible_characters]:
		match tag.mode:
			Penny.Text.Tag.MODE_PUSH:
				for inst: PennyDecorationInstance in tag:
					await inst.encounter_start(self, wait)

			Penny.Text.Tag.MODE_PUSH_POP:
				for inst: PennyDecorationInstance in tag:
					await inst.encounter_start(self, wait)
					await inst.encounter_end(self, wait)

			Penny.Text.Tag.MODE_POP:
				for inst: PennyDecorationInstance in tag:
					await inst.encounter_end(self, wait)
