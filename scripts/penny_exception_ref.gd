
class_name PennyExceptionRef extends PennyException

var address : FileAddress

func _init(_address: FileAddress, _message: String = "Uncaught exception.") -> void:
	address = _address
	super._init("[url=%s]%s %s,%s %s" % [address, address.path, address.line, address.col, _message])
