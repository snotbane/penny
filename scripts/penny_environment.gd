class_name Penny extends Node

static var inst : Penny

static func instantiate() -> void:
	inst = Penny.new()

static func start_penny_at(path : String, label : StringName) -> void :
	print("*** LOADING PENNY AT PATH %s:%s" % [path, label])
