class_name PennyException

const UNKNOWN_FILE := "UNKNOWN"

var message : String

func _init(s: String = "Uncaught exception.") -> void:
	message = "Penny exception in file '%s' : %s" % [active_file_path, s]

func push() -> void:
	printerr(message)

func _to_string() -> String:
	return message

static var active_file_path : String
