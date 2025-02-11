
## Decorator class for a [RichTextLabel]. Prints out text over time in accordance with the Penny script.
class_name Typewriter extends Node

enum PlayState {
	READY,
	PLAYING,
	DELAYED,
	PAUSED,
	COMPLETED
}

signal completed
signal prodded


var speed_stack : Array[float] = [ 40.0 ]
## How many characters per second to print out. For specific speeds mid-printout, use the <speed=x> decoration.
@export var print_speed : float = 40.0 :
	get: return speed_stack[0]
	set(value):
		speed_stack[0] = value


## Dictionary of RegEx patterns with an assigned value. Must match one single character. By default, this is used to determine if a character should or should not make a sound.
@export var character_values := {
	"[\\S]": true
}

## If enabled, delays will be treated like wait tags in that when we try to prod the typewriter to continue, we will stop at both delays and waits. (This mimics Ren'Py behavior.)
@export var treat_delay_as_wait : bool = false


@export var rtl : RichTextLabel

## (optional) controls scroll behavior.
@export var scroll_container : ScrollContainer


@export var audio_player : AudioStreamPlayer

var audio_timer := Timer.new()
## Length of time (seconds) that must pass before a new typewriter sound can be played.
var _minimum_audio_delay : float = 0.033
@export_range(0.01, 0.1, 0.001, "or_greater") var minimum_audio_delay : float = 0.033 :
	get: return _minimum_audio_delay
	set(value):
		_minimum_audio_delay = value
		audio_timer.wait_time = value

## Default audio stream to play while printing non-whitespace characters. Leave blank if using voice acting, probably.
@export var audio_sample : AudioStream


@export_category("Roger")

@export var roger : CanvasItem
@export var roger_appears_on_paused := false

## Fake label used to calculate appropriate scroll amount.
var fake_rtl : RichTextLabel
var scrollbar : VScrollBar

var is_ready : bool = false
var is_locked : bool = false
var is_typing : bool :
	get: return play_state == PlayState.PLAYING
var is_playing : bool :
	get: return play_state == PlayState.PLAYING || play_state == PlayState.DELAYED

var _play_state := PlayState.READY
var play_state : PlayState :
	get: return _play_state
	set(value):
		if _play_state == value: return
		_play_state = value

		match _play_state:
			PlayState.READY, PlayState.COMPLETED:
				is_locked = false

		match _play_state:
			PlayState.PAUSED:		roger.visible = roger_appears_on_paused
			PlayState.COMPLETED:	roger.visible = true
			_:						roger.visible = false

var subject : Cell
var message : DisplayString

var unencountered_decos : Array[DecoInst]
var unclosed_decos : Array[DecoInst]

var character_value_regex := RegEx.new()

var _cursor : float
var cursor : float :
	get: return _cursor
	set(value):
		_cursor = value
		visible_characters = floori(_cursor)


var expected_characters : int
var visible_characters : int :
	get: return rtl.visible_characters
	set (value):
		if rtl.visible_characters == value: return
		rtl.visible_characters = value

		if is_playing:
			if unencountered_decos:
				while rtl.visible_characters >= unencountered_decos.front().start_remapped:
					var deco : DecoInst = unencountered_decos.pop_front()
					is_talking = false
					await deco.encounter_start(self)
					is_talking = true
					if deco.template.is_span:
						unclosed_decos.push_back(deco)
					if not unencountered_decos:
						break

			if unclosed_decos:
				for deco in unclosed_decos:
					if rtl.visible_characters >= deco.end_remapped:
						is_talking = false
						await deco.encounter_end(self)
						is_talking = true
						unclosed_decos.erase(deco)

		if rtl.visible_characters >= expected_characters:
			rtl.visible_characters = -1

		if rtl.visible_characters == -1:
			play_state = PlayState.COMPLETED
			is_talking = false
			for deco in unclosed_decos:
				deco.encounter_end(self)
			unclosed_decos.clear()
			if scroll_container:
				scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
				scrollbar.mouse_filter = Control.MOUSE_FILTER_PASS
			completed.emit()
		elif rtl.visible_characters > 0:
			is_talking = true
			self.character_encountered(rtl.text[rtl.visible_characters - 1])

		# var last_visible_character_bounds : Rect2 = rtl.last_visible_character_bounds
		# roger.position = last_visible_character_bounds.position

		fake_rtl.visible_characters = rtl.visible_characters


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

		if subject == null: return
		if subject.instance == null: return
		if subject.instance.has_signal("talking_changed"):
			subject.instance.talking_changed.emit(_is_talking)


var next_prod_stop : int :
	get:
		for deco in unencountered_decos:
			if self.visible_characters >= deco.start_remapped:
				continue
			if deco_is_prod_stop(deco):
				return deco.start_remapped
		return -1


func _ready() -> void:
	if scroll_container:
		scrollbar = scroll_container.get_v_scroll_bar()

		## Set up the fake rtl to ensure proper scrolling
		fake_rtl = rtl.duplicate()
		fake_rtl.name = "%s (fake)" % rtl.name
		fake_rtl.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
		fake_rtl.self_modulate = Color(0,0,0,0)
		fake_rtl.focus_mode = Control.FOCUS_NONE

		rtl.add_sibling.call_deferred(fake_rtl)

	minimum_audio_delay = minimum_audio_delay
	audio_timer.autostart = false
	audio_timer.one_shot = true
	self.add_child(audio_timer)
	audio_player.stream = audio_sample
	reset()
	is_ready = true


func _process(delta: float) -> void:
	if not is_working: return

	if is_typing:
		cursor += speed * delta

	if scroll_container:
		scrollbar.value = fake_rtl.get_content_height() - scroll_container.size.y


func _exit_tree() -> void:
	self.complete()


func reset() -> void:
	if scroll_container:
		fake_rtl.text = rtl.text
		scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	expected_characters = rtl.get_total_character_count()
	play_state = PlayState.READY
	cursor = 0


func present() -> void:
	cursor = 0
	await get_tree().create_timer(0.5).timeout
	play_state = PlayState.PLAYING


func prod() -> void:
	if is_playing and not is_locked:
		cursor = next_prod_stop

	prodded.emit()


func complete() -> void:
	visible_characters = -1


func character_encountered(c: String) -> void: _character_encountered(c, get_character_value(c))
func _character_encountered(c: String, value: Variant) -> void:
	if not value: return
	if audio_timer.is_stopped():
		audio_timer.start()
		audio_player.play()


func receive(record: Record) -> void: _receive(record)
func _receive(record: Record) -> void:
	self.complete()
	subject = record.data["who"]
	message = record.data["what"]
	rtl.text = message.text
	unencountered_decos = message.decos.duplicate()
	unclosed_decos.clear()
	for deco in message.decos:
		deco.create_remap_for(self)

	if not is_ready: return

	reset()
	present()


func deco_is_prod_stop(deco: DecoInst) -> bool:
	return deco.template is DecoWait or deco.template is DecoLock or (treat_delay_as_wait and deco.template is DecoDelay)


func get_character_value(c: String) -> Variant:
	for k in character_values.keys():
		character_value_regex.compile(k)
		if character_value_regex.search(c):
			return character_values[k]
	return null


func delay(seconds: float):
	var new_state : PlayState
	if self.treat_delay_as_wait:
		new_state = PlayState.PAUSED
	else:
		new_state = PlayState.DELAYED
	self.play_state = new_state
	await self.get_tree().create_timer(seconds).timeout
	if self.play_state == new_state:
		self.play_state = PlayState.PLAYING


func wait():
	self.play_state = PlayState.PAUSED
	await self.prodded
	self.play_state = PlayState.PLAYING


func push_speed_tag(characters_per_second: float) -> void:
	speed_stack.push_back(characters_per_second)

func pop_speed_tag() -> void:
	if speed_stack.size() <= 1: return
	speed_stack.pop_back()
