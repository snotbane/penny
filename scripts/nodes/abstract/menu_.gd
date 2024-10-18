
@tool
class_name PennyMenu_ extends Node

func receive(options: Array) -> void: _receive(options)
func _receive(options: Array) -> void:
	pass

func close() -> void:
	queue_free()
	pass

