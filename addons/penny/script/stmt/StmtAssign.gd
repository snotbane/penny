@tool
class_name StmtAssign
extends StmtPath

@export_storage
var context_object_path: Penny.Path

@export_storage
var key: StringName

@export_storage
var assign: int

@export_storage
var express: Variant


func _populate_tree_item(tree: Tree, item: TreeItem) -> void:
	item.set_text(PennyDebugTree_Stmt.COLUMN_NAME, "%s %s %s" % [
		context_path_from_depth,
		PennyScript.Token.assignment_to_string(assign),
		express,
	])
	item.set_tooltip_text(PennyDebugTree_Stmt.COLUMN_NAME, "StmtAssign ::\n\t- Assigns a target to a value.")



func _populate(tokens: Array) -> void:
	super._populate(tokens)

	if tokens.is_empty():
		assign = PennyScript.Token.Assign.NONE
		express = null
		return

	assert(tokens[0].type == PennyScript.Token.Type.ASSIGNMENT, "Expected assignment token, got '%s' instead." % tokens[0])

	assign = tokens.pop_front().value

	express = Penny.Express.new_or_literal_from_tokens_destructive(tokens)


func _compile(script: PennyScript) -> void:
	super._compile(script)

	context_object_path = context_path_from_depth.popped()
	key = context_path_from_depth.ids[-1]


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	super._draw(player, record)

	record.data.value_prior = context_value_from_depth

	match assign:
		PennyScript.Token.Assign.SET:
			record.data.value_after = Penny.Evaluable.evaluate_any(express, context_path_from_depth, Penny.Evaluable.PreserveFlags.PRESERVE_PATH)

			if record.data.value_after is Penny.Cell:
				if record.data.value_after.name:
					record.data.value_after = Penny.Path.to(record.data.value_after)
				else:
					record.data.value_after.name = context_path_from_depth.ids[-1]

		PennyScript.Token.Assign.ADD:
			record.data.value_after = Penny.Express.add(
				record.data.value_prior,
				Penny.Evaluable.evaluate_any(express)
			)

		PennyScript.Token.Assign.SUBTRACT:
			record.data.value_after = Penny.Express.subtract(
				record.data.value_prior,
				Penny.Evaluable.evaluate_any(express)
			)

		PennyScript.Token.Assign.MULTIPLY:
			record.data.value_after = Penny.Express.multiply(
				record.data.value_prior,
				Penny.Evaluable.evaluate_any(express)
			)

		PennyScript.Token.Assign.DIVIDE:
			record.data.value_after = Penny.Express.divide(
				record.data.value_prior,
				Penny.Evaluable.evaluate_any(express)
			)

		PennyScript.Token.Assign.FALLBACK:
			record.data.value_after = Penny.Express.fallback(
				record.data.value_prior,
				Penny.Evaluable.evaluate_any(express)
			)

		PennyScript.Token.Assign.EXPRESS:
			record.data.value_after = express

		_:
			record.data.value_after = record.data.value_prior




func _execute(player: PennyPlayer, record: Penny.Record) -> void:
	super._execute(player, record)

	context_value_from_depth = record.data.value_after
