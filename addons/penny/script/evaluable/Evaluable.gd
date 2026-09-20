@abstract
@tool
extends Resource

enum PreserveFlags {
	## Preserve nothing; Evaluate until there are no evaluables left.
	PRESERVE_NONE = 0,
	## If the final value is an express, don't evaluate it.
	PRESERVE_EXPRESS = 1 << 0,
	## If the final value is a path, don't evaluate it (pass by reference).
	PRESERVE_PATH = 1 << 1,
	## Preserve everything. All this should do is merge constant values.
	PRESERVE_ALL = (1 << 2) - 1,
}

const OVERFLOW_LIMIT := 1024


## Shorthand for evaluating any value.
static func evaluate_any(value, context = Penny.Cell.ROOT, preserve_flags := PreserveFlags.PRESERVE_NONE) -> Variant:
	return (
		value.evaluate(context, preserve_flags)
		if value is Penny.Evaluable
		else value
	)


## Evaluate until no further evaluations can be made.
func evaluate(context = Penny.Cell.ROOT, preserve_flags := PreserveFlags.PRESERVE_NONE) -> Variant:
	var result: Variant = self
	for s in OVERFLOW_LIMIT:
		if preserve_flags & PreserveFlags.PRESERVE_EXPRESS and result is Penny.Express:
			return result

		if preserve_flags & PreserveFlags.PRESERVE_PATH and result is Penny.Path:
			return result

		result = result._evaluate_single(context)

		if result is not Penny.Evaluable:
			return result

	assert(false, "Stack overflow in Evaluable.")
	return null


## Evaluate, but change the context whenever a [Penny.Path] is encountered, and return the new context. Used when purifying [Penny.Message]s.
func evaluate_adaptive(context = Penny.Cell.ROOT, preserve_flags := PreserveFlags.PRESERVE_NONE) -> Array:
	var evals_seen : Array[Penny.Evaluable]
	var result : Variant = self
	while result is Penny.Evaluable:
		assert(not evals_seen.has(result), "Cyclical evaluation '%s' for object '%s'" % [result, context])

		evals_seen.push_back(result)
		result = result._evaluate_single(context)
		if result is Penny.Path and not result.is_relative:
			context = result.popped().evaluate(context, preserve_flags)

	return [ context, result ]


@abstract
func _evaluate_single(context) -> Variant
