
## Super simple class that ensures [Deco]s get registered properly. If you wish to use custom decorations, they must be added to one.
class_name PennyDecoRegistry extends Resource

@export var deco_resources : Array[Deco]

func register_scripts() -> void:
	for deco in deco_resources:
		Deco.register_instance(deco)
