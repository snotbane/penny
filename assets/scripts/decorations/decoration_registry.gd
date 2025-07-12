
## Super simple class that ensures [Deco]s get registered properly. If you wish to use custom decorations, they must be added to one.
class_name DecorationRegistry extends Resource

@export var decos : Array[Deco]
@export var decorations : Array


func register_decos() -> void:
	for deco in decos:
		Deco.register_instance(deco)
	for dec in decorations:
		Decoration.register(dec)
