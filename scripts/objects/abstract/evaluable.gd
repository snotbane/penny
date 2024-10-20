
## Base class for [Expr]s and [Path]s. These are objects that can be softly stored or hardly evaluated using the '@value' notation
class_name Evaluable extends RefCounted

func evaluate(host: PennyHost) -> Variant: return _evaluate(host)
func _evaluate(host: PennyHost) -> Variant:
	return null
