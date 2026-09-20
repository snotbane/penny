## Evaluates the input and jumps there. The input must evaluate to a [String].
@tool
class_name StmtJump
extends Stmt

@export_storage var express: StringName


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _get_debug_message() -> String:
	return ""


func _populate(tokens: Array) -> void:
	assert(
		tokens.size() == 1,
		"StmtJump :: Expected exactly 1 token, found %s : %s" % [
			tokens.size(),
			tokens
		]
	)
	assert(
		tokens[0].type == PennyScript.Token.Type.IDENTIFIER,
		"StmtJump :: Expected a express identifier, found '%s'" % [
			tokens[0].value
		]
	)

	express = tokens.pop_back().value


func _compile(script: PennyScript) -> void:
	pass


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	record.data = express


func _execute(player: PennyPlayer, record: Penny.Record) -> void:
	pass


func _next(player: PennyPlayer, record: Penny.Record) -> Stmt:
	return Penny.find_label(record.data)
