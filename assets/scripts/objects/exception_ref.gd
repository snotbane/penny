
class_name PennyExceptionRef extends PennyException

var address : FileAddress

func _init(_address: FileAddress, _message: String = "Uncaught exception.") -> void:
	address = _address
	super._init(_message)


func push_error() -> void:
	var main := "%s %s" % [address.pretty_string, message]
	var alt := "%s %s" % [address.output_log_string, message]

	Penny.log_error(main, Penny.ERROR_COLOR, alt)
