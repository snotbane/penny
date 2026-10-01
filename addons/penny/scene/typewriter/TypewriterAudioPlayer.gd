## Attach this script to any [AudioStreamPlayer] or similar. It will allow the node to be used to play typewriter babble.
extends Node

## Minimum length of time (seconds) that must pass before a new sound can be played.
@export_range(0.01, 0.1, 0.0001, "or_greater") var minimum_audio_delay : float = 0.033
var audio_time_accum: float

@export
var phonic_patterns: Dictionary[String, AudioStream] = {
	r"\s": null,
}
var phonic_regexes: Dictionary[RegEx, AudioStream]

var stream_default: AudioStream
var playback: AudioStreamPlaybackPolyphonic


func _ready() -> void:
	for k in phonic_patterns:
		phonic_regexes[RegEx.create_from_string(k)] = phonic_patterns[k]

	var this = self

	stream_default = this.stream
	this.stream = AudioStreamPolyphonic.new()
	this.stream.polyphony = this.max_polyphony

	this.play()
	playback = this.get_stream_playback()


func _process(delta: float) -> void:
	audio_time_accum += delta


func on_character_encountered(c: String) -> void:
	if audio_time_accum < minimum_audio_delay:
		return

	audio_time_accum = 0.0
	_character_encountered(c)


func _character_encountered(c: String) -> void:
	c = c.to_lower()
	var s : AudioStream = stream_default

	for k in phonic_regexes:
		if k.search(c):
			s = phonic_regexes[k]
			break

	if s == null:
		return

	playback.play_stream(s, 0.0, 0.0, 1.0, AudioServer.PLAYBACK_TYPE_DEFAULT)
