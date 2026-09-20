## Base class for all executable statements.
@abstract
@icon("res://addons/penny/icons/quotation_marks.svg")
@tool
class_name Stmt
extends Resource

enum {
	EXECUTE_RESPONSE_FINISHED,
	EXECUTE_RESPONSE_ABORTED,
	EXECUTE_RESPONSE_SKIPPED,

	EXECUTE_RESPONSE_MAX,
}

enum {
	HOIST_NONE,
	HOIST_INHERIT,
	HOIST_EXPLICIT,
}

enum {
	AWAIT_BYPASS,
	AWAIT_INHERIT,
	AWAIT_EXPLICIT,
}

enum Verbosity {
	NONE = 0,

	IGNORED = 1 << 0,
	NODE_ACTIVITY = 1 << 1,
	DATA_ACTIVITY = 1 << 2,
	FLOW_ACTIVITY = 1 << 3,
	DEBUG_MESSAGES = 1 << 4,
	USER_FACING = 1 << 5,

	ALL = (1 << 6) - 1,
}


const Address := preload("res://addons/penny/script/stmt/Address.gd")


signal aborted

## Tab depth; guides execution flow.
@export_storage
var depth: int = 0

@export_storage
var hoist: int = HOIST_NONE

## The most recently utilized [Penny.Path] in the same or lower depth.
@export_storage
var context_path_from_recent: Penny.Path
var context_value_from_recent: Variant:
	get: return context_path_from_recent.evaluate()
	set(value): context_path_from_recent.push(value)


## This is the path built from a series of increasing depths leading up to this statement. Allows the context to change based on tab depth.
@export_storage
var context_path_from_depth: Penny.Path
var context_value_from_depth: Variant:
	get: return context_path_from_depth.evaluate()
	set(value): context_path_from_depth.push(value)

## Returns the storage state of [member context_path_from_depth].
var context_storage_from_depth: Variant:
	get:
		if context_path_from_depth.is_empty():
			return null

		var cell_parent := context_path_from_depth.popped().evaluate()
		if cell_parent is Penny.Cell:
			return cell_parent.get_is_data_saved(context_path_from_depth.back_key())

		return null
	set(value):
		if context_path_from_depth.is_empty():
			return

		var cell_parent := context_path_from_depth.popped().evaluate()
		if cell_parent is Penny.Cell:
			assert(value is bool, "context_storage_from_depth can only be set to a boolean value.")
			cell_parent.set_is_data_saved(context_path_from_depth.back_key(), value)


var owner: PennyScript
var owner_idx: int

@export_storage
var code_address_line: int = -1



var verbosity: Verbosity:
	get: return _get_verbosity()
@abstract
func _get_verbosity() -> int


func code_address_line_to_string() -> String:
	return "ln %0*d" % [
		1,
		code_address_line,
	]


func _to_string() -> String:
	var result: String = (
		(
			"[ %s : %s ] " % [
				owner.safe_path.get_file(),
				code_address_line_to_string(),
			]
		)
		if code_address_line >= 0
		else (
			"[ %s ] " % [
				owner.safe_path.get_file(),
			]
		)
		if owner
		else "[ no script ] "
	)

	# result += "( recent context: %s / depth context: %s ) " % [
	# 	context_path_from_recent,
	# 	context_path_from_depth,
	# ]

	result += get_script().get_global_name()

	# var message := _get_debug_message()
	# if message:
	# 	result += " -> " + message

	return result

func _get_debug_message() -> String:
	return ""


func populate_tree_item(tree: Tree, item: TreeItem) -> void:
	item.set_text(0, get_script().get_global_name())

	item.set_text(PennyDebugTree_Stmt.COLUMN_ADDRESS, code_address_line_to_string())
	# item.set_text_alignment(PennyDebugTree_Stmt.COLUMN_ADDRESS, HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT)

	item.set_cell_mode(PennyDebugTree_Stmt.COLUMN_HOIST, TreeItem.CELL_MODE_ICON)
	item.set_icon(PennyDebugTree_Stmt.COLUMN_HOIST, preload("res://addons/penny/icons/Hoist.svg"))
	match hoist:
		0:
			item.set_icon_modulate(PennyDebugTree_Stmt.COLUMN_HOIST, Color.TRANSPARENT)
			item.set_tooltip_text(PennyDebugTree_Stmt.COLUMN_HOIST, "This Stmt is not hoisted and will run when executed.")

		1:
			item.set_icon_modulate(PennyDebugTree_Stmt.COLUMN_HOIST, PennyDebugTree.COLOR_DIM)
			item.set_tooltip_text(PennyDebugTree_Stmt.COLUMN_HOIST, "This Stmt's parent is hoisted, so this Stmt will also run on application start.")

		2:
			item.set_tooltip_text(PennyDebugTree_Stmt.COLUMN_HOIST, "This Stmt is hoisted and will run on application start.")

	_populate_tree_item(tree, item)

func _populate_tree_item(tree: Tree, item: TreeItem) -> void:
	pass


func populate(tokens: Array, __depth__: int) -> void:
	depth = __depth__

	_populate(tokens)

	assert(tokens.is_empty(), "Not all tokens were consumed in _populate():\n\t%s" % self )

func _populate(tokens: Array) -> void:
	pass


static func get_context_path(stmt: Stmt, target_property_name: StringName) -> Penny.Path:
	if stmt is StmtReturn or stmt == null:
		return Penny.Path.TO_OBJECT

	return stmt.get(target_property_name)


## Called when the [PennyScript] resource is compiled and all other [Stmt]s in the script exist.
func compile(script: PennyScript, idx: int) -> void:
	# ## These are already set in [PennyParser], just before populate, so no need to redo them here. They will be set again in [member ready].
	# owner = script
	# owner_idx = idx

	var stmt_head := get_stmt_in_owner(get_stmt_idx_in_depth_less_than(-1))
	context_path_from_depth = get_context_path(stmt_head, &"context_path_from_depth")

	if stmt_head and stmt_head.hoist:
		hoist = HOIST_INHERIT

	var stmt_recent := get_stmt_in_owner(get_stmt_idx_in_depth_less_than_or_equal(-1))
	context_path_from_recent = get_context_path(stmt_recent, &"context_path_from_recent")

	_compile(script)

func _compile(script: PennyScript) -> void:
	pass


## Called after the [PennyScript._ready] is loaded (editor and runtime). Links to other [Stmt]s should be initialized here, because cyclical [Stmt] references cannot be serialized.
func ready(script: PennyScript, idx: int) -> void:
	owner = script
	owner_idx = idx

	for prop: Dictionary in get_property_list():
		if not prop.usage & PROPERTY_USAGE_STORAGE: continue
		if prop.class_name != "Resource": continue

		var resource : Resource = get(prop.name)
		if resource is Stmt.Address:
			resource.populate(script)

	_ready()

func _ready() -> void:
	pass


## Creates a [Penny.Record] and initializes data for it. Not awaitable, and only happens once (not on redo).
func draw(player: PennyPlayer) -> Penny.Record:
	var result := Penny.Record.new()
	result._populate(self)
	_draw(player, result)
	return result

func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	pass


## Executes the statement for the [param player], given the data in [param record]. This can be called immediately after creating the record, or as a result of undoing or redoing.
func execute(player: PennyPlayer, record: Penny.Record):
	var result: int = await Penny.Async.which([
		_execute.bind(player, record),
		aborted
	])
	await _execute_finally(player, record, result)
	return result

func _execute(player: PennyPlayer, record: Penny.Record):
	pass

## Perform cleanup actions, regardless of how the execution ended.
func _execute_finally(player: PennyPlayer, record: Penny.Record, response: int):
	pass

## Interrupts [member execute] and proceeds.
func abort() -> void:
	_abort()
	aborted.emit()
func _abort() -> void:
	pass

## Determines the next [Stmt] to [member draw]. If null, execution will stop, or defer to the call stack.
func next(player: PennyPlayer, record: Penny.Record) -> Stmt:
	return _next(player, record)
func _next(player: PennyPlayer, record: Penny.Record) -> Stmt:
	return get_stmt_in_order()

#region Linkage


func get_stmt_in_order(inc: int = +1) -> Stmt:
	return get_stmt_in_owner(get_stmt_idx_in_order(inc))


func get_stmt_in_owner(idx: int) -> Stmt:
	return owner.stmts[idx] if idx >= 0 and idx < owner.stmts.size() else null


func get_stmt_idx_in_order(inc: int) -> int:
	return owner_idx + inc


func get_stmt_idx_in_depth_equal(inc: int) -> int:
	var cursor := get_stmt_idx_in_order(inc)
	while cursor >= 0 and cursor < owner.stmts.size():
		var cursor_stmt := get_stmt_in_owner(cursor)
		if cursor_stmt.depth == self.depth:
			return cursor

		if cursor_stmt.depth < self.depth:
			break

		cursor = cursor_stmt.get_stmt_idx_in_order(inc)

	return -1


func get_stmt_idx_in_depth_less_than_or_equal(inc: int) -> int:
	var cursor := get_stmt_idx_in_order(inc)
	while cursor >= 0 and cursor < owner.stmts.size():
		var cursor_stmt := get_stmt_in_owner(cursor)
		if cursor_stmt.depth <= self.depth:
			return cursor

		cursor = cursor_stmt.get_stmt_idx_in_order(inc)

	return -1


func get_stmt_idx_in_depth_less_than(inc: int) -> int:
	if self.depth == 0:
		return -1

	var cursor := get_stmt_idx_in_order(inc)
	while cursor >= 0 and cursor < owner.stmts.size():
		var cursor_stmt := get_stmt_in_owner(cursor)
		if cursor_stmt.depth < self.depth:
			return cursor

		cursor = cursor_stmt.get_stmt_idx_in_order(inc)

	return -1


func get_stmt_idx_in_depth_greater_than_or_equal(inc: int) -> int:
	var cursor := get_stmt_idx_in_order(inc)
	while cursor >= 0 and cursor < owner.stmts.size():
		var cursor_stmt := get_stmt_in_owner(cursor)
		if cursor_stmt.depth >= self.depth:
			return cursor

		cursor = cursor_stmt.get_stmt_idx_in_order(inc)

	return -1


func get_stmt_idx_in_depth_greater_than(inc: int) -> int:
	var cursor := get_stmt_idx_in_order(inc)
	while cursor >= 0 and cursor < owner.stmts.size():
		var cursor_stmt := get_stmt_in_owner(cursor)
		if cursor_stmt.depth > self.depth:
			return cursor

		cursor = cursor_stmt.get_stmt_idx_in_order(inc)

	return -1


func get_stmt_idxs_nested() -> PackedInt32Array:
	var result: PackedInt32Array = []

	var cursor := get_stmt_idx_in_depth_greater_than(+1)
	while cursor >= 0 and cursor < owner.stmts.size():
		result.push_back(cursor)

		var cursor_stmt := get_stmt_in_owner(cursor)
		cursor = cursor_stmt.get_stmt_idx_in_depth_equal(+1)

	return result

#endregion
