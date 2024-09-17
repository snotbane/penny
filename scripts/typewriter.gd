
## Decorator class for a [RichTextLabel]. Prints out text over time in accordance with the Penny script.
class_name Typewriter extends Node

## How many characters per second to print out. For specific speeds mid-printout, use the <speed=X> decoration.
@export var print_speed : float = 50.0

## How many sfx per second to play. This will also scale with a <speed> decoration.
@export var audio_speed : float = 10.0

## Audio stream to play while printing non-whitespace characters. Leave blank if using voice acting, probably.
@export var audio_sample : AudioStream

@onready var rtl : RichTextLabel = get_parent()

var cursor : float = 0.0

var cps : float :
	get: return print_speed

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	cursor += cps * delta
	rtl.visible_characters = floori(cursor)

func reset() -> void:
	cursor = 0
	rtl.visible_characters = 0
