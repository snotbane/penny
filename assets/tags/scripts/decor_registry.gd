
## Super simple class that ensures [Deco]s get registered properly. If you wish to use custom decors, they must be added to one.
class_name DecorRegistry extends Resource

@export var decors : Array

func register_all_decors() -> void:
	for decor in decors:
		Decor.register_in_master(decor)
