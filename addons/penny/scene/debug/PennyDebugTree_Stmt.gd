class_name PennyDebugTree_Stmt
extends PennyDebugTree

enum {
	COLUMN_ADDRESS,
	COLUMN_NAME,
	COLUMN_HOIST,

	COLUMN_MAX
}

var penny_script : PennyScript
var stmt_items: Dictionary[Stmt, TreeItem]

func _init() -> void:
	super._init()

	hide_root = true
	select_mode = Tree.SELECT_ROW
	columns = COLUMN_MAX

	set_column_expand(COLUMN_NAME, true)
	set_column_expand_ratio(COLUMN_NAME, 5)

	set_column_expand(COLUMN_ADDRESS, true)
	set_column_expand_ratio(COLUMN_ADDRESS, 1)

	set_column_expand(COLUMN_HOIST, false)



func on_script_selected(script: PennyScript) -> void:
	penny_script = script
	refresh()


func _construct_tree() -> void:
	root = create_item()

	if penny_script == null:
		return

	for stmt in penny_script.stmts:
		create_stmt_item(stmt)


func create_stmt_item(stmt: Stmt) -> TreeItem:
	var parent_stmt := stmt.get_stmt_in_owner(stmt.get_stmt_idx_in_depth_less_than(-1))
	var result := create_item(stmt_items.get(parent_stmt, root))
	stmt_items[stmt] = result

	stmt.populate_tree_item(self, result)



	return result
