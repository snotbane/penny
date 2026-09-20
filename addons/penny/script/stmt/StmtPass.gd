## Dummy statement that does nothing when executed and always advances to the immediate next [Stmt] in order.
@tool
class_name StmtPass
extends Stmt

func _get_verbosity() -> Verbosity:
	return Verbosity.IGNORED


func _populate_tree_item(tree: Tree, item: TreeItem) -> void:
	item.set_text(PennyDebugTree_Stmt.COLUMN_NAME, "pass")
	item.set_tooltip_text(PennyDebugTree_Stmt.COLUMN_NAME, "StmtPass ::\n\tAdvances to the next Stmt.")


func _populate(tokens: Array) -> void:
	assert(
		tokens.is_empty(),
		"StmtPass :: Expected 0 tokens, received %s." % [
			tokens.size()
	])
