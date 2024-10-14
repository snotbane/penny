
class_name PennyException extends RefCounted

const UNKNOWN_FILE := "UNKNOWN"

static var active_file_path : String

var message : String

func _init(_message: String = "Uncaught exception.") -> void:
	message = _message

func push() -> void:
	Penny.log_error(message)

func _to_string() -> String:
	return message
