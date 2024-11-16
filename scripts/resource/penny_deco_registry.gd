
## Super simple class that ensures [Deco]s get registered properly. If you wish to use custom decorations, they must be added to one.
class_name PennyDecoRegistry extends Resource

@export var deco_scripts : Array[Script]

func register_scripts() -> void:
	for script in deco_scripts:
		var deco : Deco = script.new()
		Deco.register_instance(deco)
