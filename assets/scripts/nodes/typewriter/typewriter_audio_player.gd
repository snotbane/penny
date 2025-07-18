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


func receive_character(c: String) -> void:
	if _audio_timer < minimum_audio_delay: return
	_audio_timer = 0.0

	_receive_character(c)
func _receive_character(c: String) -> void:
	c = c.to_lower()
	stream = default_audio_stream

	if char_map.has(c):
		stream = char_map[c]
	else:
		for k in regex_map.keys():
			regex.compile(k)
			if not regex.search(c): continue
			stream = regex_map[k]
			break

	play()
