
class_name PennyPrompt extends PennyNode

var options : Array

func _ready() -> void:
	receive_options(object.get_value(PennyObject.OPTIONS_KEY))


func receive_options(_options: Array) -> void:
	options = _options
	if options:
		_receive_options(options)
	else:
		PennyException.new("Prompt was not supplied with any options.").push()
		self.advance_event = AdvanceEvent.ON_EXITING
		queue_free()
func _receive_options(_options: Array) -> void:
	pass


func receive_response(option: Path) -> void:
	object.set_value(PennyObject.RESPONSE_KEY, option)
	_receive_response(option)
func _receive_response(option: Path) -> void:
	close()
