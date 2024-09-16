extends Node

@export var label : StringName = 'start'
@export var autoload : bool = false

func _ready() -> void :
	if autoload :
		start_penny_here()

func start_penny_here() -> void :
	if not Penny.valid:
		printerr("Penny environment is not valid, so PennyLoader will not be instantiated.")
		return

	var inst = PennyHost.new(label)
	add_sibling.call_deferred(inst)

