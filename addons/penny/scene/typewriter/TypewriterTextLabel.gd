## Text box specifically designed to print out text over time. Works with unique Penny decorations.
class_name TypewriterTextLabel
extends RichTextLabel

enum {
	READY,
	PLAYING,
	FINISHED,
	RESETTING,
}




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

		text = source_text
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
	present_delay_timer = Timer.new()
	present_delay_timer.autostart = false
	present_delay_timer.one_shot = true
	present_delay_timer.wait_time = 0.5
	add_child(present_delay_timer)


# 	shaper = duplicate(0)
# 	shaper.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
# 	add_child(shaper)


func _ready() -> void:
	visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING


var processing: bool = false
func _process(delta: float) -> void:
	time_elapsed_stamp = Time.get_ticks_usec() - time_elapsed_stamp

	if typing and not processing:
		processing = true
		await add_visible_characters_partial(speed * delta)
		processing = false



func abort() -> void:
	state = FINISHED


func complete() -> void:
	abort()
	visible_characters = -1


func reset_hard() -> void:
	abort()
	visible_characters = 0


func present(__source__):
	source = __source__
	state = PLAYING
	pausing = true

	time_prepped_stamp = Time.get_ticks_usec()

	await Penny.Async.any([_present, playing_changed])


func _present():
	if present_delay > 0.1:
		present_delay_timer.start()
		await present_delay_timer.timeout

	pausing = false


func reset():
	state = RESETTING

	await Penny.Async.all([])

	reset_hard()


func add_visible_characters_partial(value: float):
	visible_characters_partial += value

	if visible_characters_partial < 0:
		visible_characters = -1
		visible_characters_partial = visible_characters_max
		return

	var visible_characters_target := clampi(floori(visible_characters_partial), 0, visible_characters_max)

	if visible_characters == visible_characters_target:
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
	if not source_tags.has(visible_characters):
		return

	for tags: Array in source_tags[visible_characters]:
		for tag: Penny.Text.Tag in tags:
			match tag.mode:
				Penny.Text.Tag.MODE_PUSH:
					for inst: PennyDecorationInstance in tag:
						await inst.encounter_start(self)

				Penny.Text.Tag.MODE_POP:
					for inst: PennyDecorationInstance in tag:
						await inst.encounter_end(self)

				Penny.Text.Tag.MODE_PUSH_POP:
					for inst: PennyDecorationInstance in tag:
						await inst.encounter_start(self)
						await inst.encounter_end(self)
