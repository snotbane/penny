
class_name PennyPrompt extends CellNode

var options : Array

func _populate() -> void:
	receive_options(host, cell.get_value(Cell.K_OPTIONS))


func receive_options(_host: PennyHost, _options: Array) -> void:
	options = _options

	var has_visible_option := false
	for option in options:
		if not option.evaluate().get_value(Cell.K_VISIBLE): continue
		has_visible_option = true
		break

	if has_visible_option:
		_receive_options(host, options)
	else:
		print("Prompt '%s' was not supplied with any visible options. Advancing." % cell)
		queue_free()
		self.advanced.emit.call_deferred()
func _receive_options(_host: PennyHost, _options: Array) -> void:	pass


func receive_response(option: Cell.Ref) -> void:
	cell.set_value(Cell.K_RESPONSE, option)
	self.close()
	self.advanced.emit()
	_receive_response(option)
func _receive_response(option: Cell.Ref) -> void: pass
