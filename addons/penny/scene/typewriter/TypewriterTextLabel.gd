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

## If enabled, clicking this Node will initiate a poke.
@export
var click_poke: bool = true:
	get: return gui_input.is_connected(_gui_input_click_poke)
	set(value):
		if click_poke == value: return
		if value:
			gui_input.connect(_gui_input_click_poke)
		else:
			gui_input.disconnect(_gui_input_click_poke)


func _gui_input_click_poke(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			poke()

var poke_locked: bool


## Forces the typewriter to be marked as complete.
func advance() -> void:
	if state < FINISHED:
		state = FINISHED
	print("ADVANCE")
	advanced.emit()


## Initiates a user poke. You can call this method to add your own custom functionality.
func poke() -> void:
	match state:
		PLAYING:
			if poke_locked:
				return
			print("POKE! (PLAYING)")
			complete()
			poked.emit()

		FINISHED:
			print("POKE! (FINISHED)")
			advance()



var present_delay_timer: Timer
## The amount of time to wait before presenting text.
@export_range(0.0, 1.0, 0.01, "or_greater")
var present_delay: float = 0.5:
	set(value):
		present_delay = value

		if present_delay > 0.1:
			present_delay_timer.wait_time = value


static var rate_base: float:
	get: return ProjectSettings.get_setting("penny/typewriter/rate_base", 100.0)
	set(value): ProjectSettings.set_setting("penny/typewriter/rate_base", value)

var rate_stack: PackedFloat32Array

var speed_stack: PackedFloat32Array

var speed: float:
	get:
		var rate: float = rate_stack[-1] if rate_stack else rate_base
		var scalar: float = speed_stack[-1] if speed_stack else 1.0

		return rate * scalar


signal playing_changed
signal state_changed
var state: int = READY:
	set(value):
		if state == value: return

		if state == PLAYING or value == PLAYING:
			playing_changed.emit()

		state = value
		print("state :: %s" % [ state ])

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
		characters_time_stamps.resize(visible_characters_max)
		characters_time_stamps.fill(INF)


var source_text: String
var source_tags: Dictionary


var visible_characters_max: int

var visible_characters_partial: float = 0.0


var time_elapsed_stamp: int
var time_prepped_stamp: int
var characters_time_stamps: PackedInt32Array


# var shaper: RichTextLabel


func _init() -> void:
	gui_input.connect(_gui_input_click_poke)

	present_delay_timer = Timer.new()
	present_delay_timer.autostart = false
	present_delay_timer.one_shot = true
	present_delay_timer.wait_time = 0.5
	add_child(present_delay_timer)



# 	shaper = duplicate(0)
# 	shaper.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
# 	add_child(shaper)


func _ready() -> void:
	visible_characters = 0
	# visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING


var processing = null
func _process(delta: float) -> void:
	time_elapsed_stamp = Time.get_ticks_usec() - time_elapsed_stamp

	if typing and processing != source:
		processing = source
		await add_visible_characters_partial(speed * delta)
		processing = null


func present(__source__):
	assert(state == READY)

	source = __source__
	state = PLAYING
	pausing = true

	time_prepped_stamp = Time.get_ticks_usec()

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

	state = FINISHED
	set_visible_characters_partial(-1)


func reset():
	state = RESETTING

	# await Penny.Async.all([ insts (such as dropout) ])

	visible_characters_partial = 0.0
	visible_characters = 0

	await get_tree().process_frame

	state = READY


func add_visible_characters_partial(value: float):
	await set_visible_characters_partial(visible_characters_partial + value)

func set_visible_characters_partial(value: float):
	visible_characters_partial = value

	if visible_characters_partial < 0:
		visible_characters = visible_characters_max
		visible_characters_partial = visible_characters_max
		for i in characters_time_stamps.size():
			characters_time_stamps[i] = minf(characters_time_stamps[i], time_elapsed_stamp)
		return

	var visible_characters_target := clampi(floori(visible_characters_partial), 0, visible_characters_max)

	if visible_characters >= visible_characters_target:
		complete()
		return

	var inc := signi(visible_characters_target - visible_characters)
	assert(inc != 0)

	while visible_characters != visible_characters_target:
		characters_time_stamps[visible_characters] = time_elapsed_stamp
		visible_characters += inc

		if inc < 0:
			continue

		await _handle_elements()

	visible_characters_partial = float(visible_characters) + fmod(visible_characters_target, 1.0)


func _handle_elements():
	if state != PLAYING:
		return

	if not source_tags.has(visible_characters):
		return

	for tag: Penny.Text.Tag in source_tags[visible_characters]:
		match tag.mode:
			Penny.Text.Tag.MODE_PUSH:
				for inst: PennyDecorationInstance in tag:
					await inst.encounter_start(self)

			Penny.Text.Tag.MODE_PUSH_POP:
				for inst: PennyDecorationInstance in tag:
					await inst.encounter_start(self)
					await inst.encounter_end(self)

			Penny.Text.Tag.MODE_POP:
				for inst: PennyDecorationInstance in tag:
					await inst.encounter_end(self)
