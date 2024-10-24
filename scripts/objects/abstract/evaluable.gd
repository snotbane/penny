
## Base class for [Expr]s and [Path]s. These are objects that can be softly stored or hardly evaluated using the '@value' notation
class_name Evaluable extends RefCounted

func evaluate(context: PennyObject) -> Variant: return _evaluate(context)
func _evaluate(context: PennyObject) -> Variant:
	return null

func evaluate_as_lookup(root: PennyObject) -> Lookup:
	var result = _evaluate(root)
	# if not result is Lookup:
	# 	host.cursor.create_exception("Couldn't evaluate '%s' as Lookup because it isn't a Lookup." % self).push()
	# 	return null
	# if not result.valid:
	# 	host.cursor.create_exception("Couldn't evaluate '%s' as Lookup because it doesn't exist in any LookupTable." % result).push()
	# 	return null
	return result
