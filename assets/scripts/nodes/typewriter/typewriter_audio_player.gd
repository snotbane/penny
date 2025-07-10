class_name TypewriterAudioStreamPlayer extends AudioStreamPlayer

## Length of time (seconds) that must pass before a new typewriter sound can be played.
@export_range(0.01, 0.1, 0.0001, "or_greater") var minimum_audio_delay : float = 0.033
var _audio_timer := 0.0

var char_map : Dictionary[String, AudioStream]
var regex_map : Dictionary[String, AudioStream]
@export var phonic_map : Dictionary[String, AudioStream] = {
	r"[\s]": null
} :
	get: return char_map.merged(regex_map)
	set(value): for k in value.keys(): (char_map if k.length() == 1 else regex_map)[k] = value[k]

var regex := RegEx.new()
var default_audio_stream : AudioStream


func _ready() -> void:
	default_audio_stream = stream


func _process(delta: float) -> void:
	_audio_timer += delta


func receive_character(char: String) -> void:
	if _audio_timer < minimum_audio_delay: return
	_audio_timer = 0.0

	_receive_character(char)
func _receive_character(char: String) -> void:
	char = char.to_lower()
	stream = default_audio_stream

	if char_map.has(char):
		stream = char_map[char]
	else:
		for k in regex_map.keys():
			regex.compile(k)
			if not regex.search(char): continue
			stream = regex_map[k]
			break

	play()
