extends Node

@export_file("*.pny") var path : String
@export var label : StringName
@export var autoload : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void :
	if autoload :
		start_penny_here()

func start_penny_here() -> void :
	Penny.start_penny_at(path, label)

