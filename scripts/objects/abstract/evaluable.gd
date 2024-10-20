
## Base class for [Expr]s and [Path]s. These are objects that can be softly stored or hardly evaluated using the '@value' notation
class_name Evaluable extends RefCounted

func evaluate(host: PennyHost, soft: bool = false) -> Variant: return _evaluate(host, soft)
func _evaluate(host: PennyHost, soft: bool = false) -> Variant:
	return null

func evaluate_as_lookup(host: PennyHost) -> Lookup:
	var result = _evaluate(host)
	if not result is Lookup:
		host.cursor.create_exception("Couldn't evaluate '%s' as Lookup because it isn't a Lookup." % self).push()
		return null
	if not result.valid:
		host.cursor.create_exception("Couldn't evaluate '%s' as Lookup because it doesn't exist in any LookupTable." % result).push()
		return null
	return result
