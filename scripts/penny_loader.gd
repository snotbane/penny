
## Simple node that opens a PennyHost at a specified label.
extends Node

@export var label : StringName = 'start'
@export var autoload : bool = false

@export var settings : PennySettings = load("res://addons/penny_godot/templates/default_settings.tres")

func _ready() -> void :
	if autoload :
		start_penny_here()

func start_penny_here() -> void :
	if not Penny.valid:
		printerr("Penny environment is not valid, so PennyLoader will not be instantiated.")
		return

	var inst = PennyHost.new(label, settings)
	add_sibling.call_deferred(inst)

