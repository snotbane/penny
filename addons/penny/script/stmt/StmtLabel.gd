## Creates a global label which execution can jump or call from anywhere. At runtime, this does nothing.
@tool
class_name StmtLabel
extends StmtPass

@export var label: StringName

func _get_verbosity() -> Verbosity:
	return Verbosity.IGNORED


func _get_debug_message() -> String:
	return label


func _populate(tokens: Array) -> void:
	assert(tokens.size() == 1,
		"StmtLabel :: Expected exactly one token, received %s." % [
			tokens.size()
		]
	)

	label = tokens.pop_front().value


func _compile(script: PennyScript) -> void:
	super._compile(script)

	script.add_label(label, self)
