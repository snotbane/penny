
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


## How many characters per second to print out. For specific speeds mid-printout, use the <speed=x> decoration.
@export var print_speed : float = 50.0 :
	get: return speed_stack[0]
	set(value):
		speed_stack[0] = value
var speed_stack : Array[float] = [ 50.0 ]

## Number of characters that must be printed in order to play a sound.
@export var characters_per_audio := 2

## Default audio stream to play while printing non-whitespace characters. Leave blank if using voice acting, probably.
@export var audio_sample : AudioStream

## Dictionary of RegEx patterns that determines how much to advance the audio cursor. I.E. values higher than [member characters_per_audio] will definitely play a sound. Each key should only be one character long. If a pattern is not matched, default value is 1.
@export var character_audio_weights := {
	"[\\s]": 0,
	"[.,:;?!]": 10
}

## If enabled, delays will be treated like wait tags in that when we try to prod the typewriter to continue, we will stop at both delays and waits. (This mimics Ren'Py behavior.)
@export var treat_delay_as_wait : bool = false


@export var rtl : RichTextLabel

## (optional) controls scroll behavior.
@export var scroll_container : ScrollContainer


@export var audio_player : AudioStreamPlayer


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

var message : DisplayText

var unencountered_decos : Array[DecoInst]
var unclosed_decos : Array[DecoInst]

var audio_cursor := 0
var audio_weight_regex := RegEx.new()

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

		var difference : int = max(0, value - rtl.visible_characters)
		for i in difference:
			audio_cursor += get_audio_weight(rtl.text[rtl.visible_characters + i - 1])

		rtl.visible_characters = value

		if is_playing:
			if unencountered_decos:
				while rtl.visible_characters >= unencountered_decos.front().start_remapped:
					var deco : DecoInst = unencountered_decos.pop_front()
					await deco.encounter_start(self)
					if deco.template.requires_end_tag:
						unclosed_decos.push_back(deco)
					if not unencountered_decos:
						break
			if unclosed_decos:
				for deco in unclosed_decos:
					if rtl.visible_characters >= deco.end_remapped:
						await deco.encounter_end(self)
						unclosed_decos.erase(deco)

		if rtl.visible_characters >= expected_characters:
			rtl.visible_characters = -1

		if rtl.visible_characters == -1:
			play_state = PlayState.COMPLETED
			for deco in unclosed_decos:
				deco.encounter_end(self)
			unclosed_decos.clear()
			if scroll_container:
				scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
				scrollbar.mouse_filter = Control.MOUSE_FILTER_PASS
			completed.emit()
		elif audio_cursor >= characters_per_audio and rtl.text[rtl.visible_characters - 1] != " ":
			audio_cursor = 0
			audio_player.play()
		fake_rtl.visible_characters = rtl.visible_characters


var speed : float :
	get: return self.speed_stack.back()


var is_working : bool :
	get: return visible_characters != -1


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
		fake_rtl.add_theme_color_override('default_color', Color(0,0,0,0))

		rtl.add_sibling.call_deferred(fake_rtl)

	audio_player.stream = audio_sample
	reset()
	is_ready = true


func _process(delta: float) -> void:
	if not is_working: return

	if is_typing:
		cursor += speed * delta

	if scroll_container:
		scrollbar.value = fake_rtl.get_content_height() - scroll_container.size.y


func reset() -> void:
	if scroll_container:
		fake_rtl.text = rtl.text
		scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	expected_characters = rtl.get_total_character_count()
	play_state = PlayState.READY
	cursor = 0


func present() -> void:
	play_state = PlayState.PLAYING
	cursor = 0


func prod() -> void:
	if is_playing and not is_locked:
		cursor = next_prod_stop

	prodded.emit()


func _on_message_received(_message: DisplayText) -> void:
	message = _message
	rtl.text = message.to_string()
	unencountered_decos = message.decos.duplicate()
	unclosed_decos.clear()
	for deco in message.decos:
		deco.create_remap_for(self)

	if not is_ready: return

	reset()
	present()


func _on_dialog_present() -> void:
	present()


func deco_is_prod_stop(deco: DecoInst) -> bool:
	return deco.template is DecoWait or deco.template is DecoLock or (treat_delay_as_wait and deco.template is DecoDelay)


func get_audio_weight(c: String) -> int:
	for k in character_audio_weights.keys():
		audio_weight_regex.compile(k)
		if audio_weight_regex.search(c):
			return character_audio_weights[k]
	return 1


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
