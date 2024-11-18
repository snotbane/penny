
## Base class for [Expr]s and [Path]s. These are objects that can be softly stored or hardly evaluated using the '@value' notation
class_name Evaluable extends RefCounted

## Evaluate one layer. Non-recursive.
func evaluate_shallow(context: PennyObject) -> Variant: return _evaluate_shallow(context)
func _evaluate_shallow(context: PennyObject) -> Variant:
	return null

# func evaluate(context: PennyObject, fallback: PennyObject = null) -> Variant:
# 	var result : Variant = self._evaluate(context)
# 	if result == null and fallback:
# 		result = self._evaluate(fallback)
# 	return result
# func _evaluate(context: PennyObject) -> Variant:
## Evaluate until no further evaluations can be made.
func evaluate(context: PennyObject) -> Variant:
	var evals_seen : Array[Evaluable]
	var result : Variant = self
	while result is Evaluable:
		if evals_seen.has(result):
			PennyException.new("Cyclical evaluation '%s' for object '%s'" % [result, context]).push()
			return null
		evals_seen.push_back(result)
		result = result.evaluate_shallow(context)
	return result
