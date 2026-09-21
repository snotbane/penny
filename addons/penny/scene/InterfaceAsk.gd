## Default implementation of a dialog handler.
extends Control

@onready
var option_template : InstancePlaceholder = $v_box_container/option_template

func handle(record: Penny.Record):
	var option_nodes : Array[Node] = []
	option_nodes.resize(record.data.options.size())

	var option_signals : Array = []
	option_signals.resize(record.data.options.size())

	for i in record.data.options.size():
		option_nodes[i] = option_template.create_instance()
		assert(
			option_nodes[i].has_method("populate"),
			"Option node must have a populate method which takes a Variant."
		)
		assert(
			option_nodes[i].has_signal("selected"),
			"Option node must have a signal 'selected'."
		)

		option_nodes[i].populate(record.data.options[i])
		option_signals[i] = option_nodes[i].selected

	var result : int = await Penny.Async.which(option_signals)

	queue_free()

	return result
