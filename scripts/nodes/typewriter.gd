
## Decorator class for a [RichTextLabel]. Prints out text over time in accordance with the Penny script.
class_name Typewriter extends Node

signal completed

## How many characters per second to print out. For specific speeds mid-printout, use the <speed=X> decoration.
@export var print_speed : float = 50.0

## How many sfx per second to play. This will also scale with a <speed> decoration.
@export var audio_speed : float = 10.0

## Audio stream to play while printing non-whitespace characters. Leave blank if using voice acting, probably.
@export var audio_sample : AudioStream

@export var rtl : RichTextLabel

## (optional) controls scroll behavior.
@export var scroll_container : ScrollContainer

## Fake label used to calculate appropriate scroll amount.
var fake_rtl : RichTextLabel
var scrollbar : VScrollBar

var is_ready : bool = false
var is_playing : bool = false

var cursor : float = 0.0
var expected_characters : int
var visible_characters : int :
	get: return rtl.visible_characters
	set (value):
		if rtl.visible_characters == value: return
		rtl.visible_characters = value
		if rtl.visible_characters >= expected_characters:
			rtl.visible_characters = -1
		## Kind of weird syntax but we do this so that we ensure these methods get called whether the visible characters reached the end or if we manually skipped to the end by setting it directly to -1
		if rtl.visible_characters == -1:
			if scroll_container:
				scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
				scrollbar.mouse_filter = Control.MOUSE_FILTER_PASS
			completed.emit()
		fake_rtl.visible_characters = rtl.visible_characters


var cps : float :
	get: return print_speed

func _ready() -> void:
	if scroll_container:
		scrollbar = scroll_container.get_v_scroll_bar()

		## Set up the fake rtl to ensure proper scrolling
		fake_rtl = rtl.duplicate()
		fake_rtl.name = "%s (fake)" % rtl.name
		fake_rtl.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
		fake_rtl.add_theme_color_override('default_color', Color(0,0,0,0))

		rtl.add_sibling.call_deferred(fake_rtl)
	reset()
	is_ready = true

func _process(delta: float) -> void:
	if not working: return

	if is_playing:
		cursor += cps * delta
		visible_characters = floori(cursor)

	if scroll_container:
		scrollbar.value = fake_rtl.get_content_height() - scroll_container.size.y

func reset() -> void:
	if scroll_container:
		fake_rtl.text = rtl.text
		scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	expected_characters = rtl.get_total_character_count()
	cursor = 0
	visible_characters = 0


func present() -> void:
	is_playing = true

func _on_dialog_received() -> void:
	if is_ready:
		reset()

func _on_dialog_present() -> void:
	present()



## WATCHER METHODS

var working : bool :
	get: return visible_characters != -1

func prod_work() -> void:
	## Eventually, go to the next wait input chararcter -- not necessarily the whole thing.
	visible_characters = -1




