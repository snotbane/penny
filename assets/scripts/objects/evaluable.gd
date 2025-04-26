
## Base class for [Expr]s and [Cell.Ref]s. These are objects that can be softly stored or hardly evaluated using the '@value' notation
class_name Evaluable extends RefCounted


## Evaluate until no further evaluations can be made.
func evaluate(context := Cell.ROOT) -> Variant:
	var result : Variant = self
	while result is Evaluable:
		result = result._evaluate(context)
	return result


## Evaluate, but change the context whenever a [Cell.Ref] is encountered.
func evaluate_adaptive(context := Cell.ROOT) -> Dictionary:
	var evals_seen : Array[Evaluable]
	var result : Variant = self
	while result is Evaluable:
		if evals_seen.has(result):
			printerr("Cyclical evaluation '%s' for object '%s'" % [result, context])
			break
		evals_seen.push_back(result)
		result = result._evaluate(context)
		if result is Cell.Ref and not result.rel:
			var new_context_ref : Cell.Ref = result.duplicate()
			new_context_ref.ids.remove_at(new_context_ref.ids.size() - 1)
			context = new_context_ref.evaluate(context)
	return {
		&"context": context,
		&"value": result
	}


## Evaluate one layer. Non-recursive.
func _evaluate(context : Cell) -> Variant: return null
