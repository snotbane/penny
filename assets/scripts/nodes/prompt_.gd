
class_name PennyPrompt extends CellNode

var options : Array

func _ready() -> void:
	receive_options(cell.get_value(Cell.K_OPTIONS))
	# super._ready()


func receive_options(_options: Array) -> void:
	options = _options
	if options:
		_receive_options(options)
	else:
		printerr("Prompt was not supplied with any options.")
		queue_free()
func _receive_options(_options: Array) -> void:	pass


func receive_response(option: Cell.Ref) -> void:
	cell.set_value(Cell.K_RESPONSE, option)
	self.advanced.emit()
	_receive_response(option)
func _receive_response(option: Cell.Ref) -> void: pass
