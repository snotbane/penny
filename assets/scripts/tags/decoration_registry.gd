
## Super simple class that ensures [Deco]s get registered properly. If you wish to use custom decorations, they must be added to one.
class_name DecorationRegistry extends Resource

@export var decorations : Array


func register_decos() -> void:
	for dec in decorations:
		Decoration.register(dec)
