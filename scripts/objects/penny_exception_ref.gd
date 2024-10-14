
class_name PennyExceptionRef extends PennyException

var address : FileAddress

func _init(_address: FileAddress, _message: String = "Uncaught exception.") -> void:
	address = _address
	super._init("%s : %s" % [address.pretty_string, _message])
