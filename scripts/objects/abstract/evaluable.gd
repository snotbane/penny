
## Base class for [Expr]s and [Path]s. These are objects that can be softly stored or hardly evaluated using the '@value' notation
class_name Evaluable extends RefCounted

## Evaluate one layer. Non-recursive.
func evaluate(context: PennyObject) -> Variant: return _evaluate(context)
func _evaluate(context: PennyObject) -> Variant:
	return null

## Evaluate until no further evaluations can be made.
func evaluate_deep(context: PennyObject) -> Variant:
	var evals_seen : Array[Evaluable]
	var result : Variant = self
	while result is Evaluable:
		if evals_seen.has(result):
			PennyException.new("Cyclical evaluation '%s' for object '%s'" % [result, context]).push()
			return null
		evals_seen.push_back(result)
		result = result.evaluate(context)
	return result


# func evaluate_deep(context: PennyObject) -> Variant: return _evaluate_deep(context)
# func _evaluate_deep(context: PennyObject) -> Variant:
# 	return _evaluate(context)

func evaluate_as_lookup(root: PennyObject) -> Lookup:
	var result = _evaluate(root)
	# if not result is Lookup:
	# 	host.cursor.create_exception("Couldn't evaluate '%s' as Lookup because it isn't a Lookup." % self).push()
	# 	return null
	# if not result.valid:
	# 	host.cursor.create_exception("Couldn't evaluate '%s' as Lookup because it doesn't exist in any LookupTable." % result).push()
	# 	return null
	return result
