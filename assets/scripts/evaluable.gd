
## Base class for [Expr]s and [Cell.Ref]s. These are objects that can be softly stored or hardly evaluated using the '@value' notation
class_name Evaluable extends RefCounted


## Evaluate until no further evaluations can be made.
func evaluate(context := Cell.ROOT) -> Variant:
	var evals_seen : Array[Evaluable]
	var result : Variant = self
	while result is Evaluable:
		if evals_seen.has(result):
			printerr("Cyclical evaluation '%s' for object '%s'" % [result, context])
			return null
		evals_seen.push_back(result)
		result = result._evaluate_shallow(context)
	return result


## Evaluate one layer. Non-recursive.
func _evaluate_shallow(context := Cell.ROOT) -> Variant: return _evaluate(context)
func _evaluate(context : Cell) -> Variant: return null
