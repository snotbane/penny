
## Base class for all executable statemetnts.
class_name Stmt extends RefCounted

enum Verbosity {
	NONE = 0,
	USER_FACING = 1 << 0,
	DEBUG_MESSAGES = 1 << 1,
	FLOW_ACTIVITY = 1 << 2,
	DATA_ACTIVITY = 1 << 3,
	NODE_ACTIVITY = 1 << 4,
	IGNORED = 1 << 5,
	MAX = (1 << 6) - 1,
}

const VERBOSITY_NAMES : PackedStringArray = [
	"User Facing:1",
	"Debug Messages:2",
	"Flow Activity:4",
	"Data Activity:8",
	"Node Activity:16",
	"Ignored:32"
]

signal aborted

var owner : PennyScript
var index : int
var depth : int
var hash_id : int
var _debug_string_do_not_use_for_anything_else_seriously_i_mean_it : String

var prev_in_order : Stmt
var prev_in_same_depth : Stmt
var prev_in_same_or_lower_depth : Stmt
var prev_in_lower_depth : Stmt
var prev_in_higher_depth : Stmt
var next_in_order : Stmt
var next_in_same_depth : Stmt
var next_in_same_or_lower_depth : Stmt
var next_in_lower_depth : Stmt
var next_in_higher_depth : Stmt

var index_in_same_depth_chain : int = -1

var context_ref : Path
var context : Cell :
	get: return context_ref.evaluate()

## Defines whether or not this statement should show up in history. -1 = always show, even to end user. Values greater than 0 are used for debugging purposes.
var verbosity : int :
	get: return _get_verbosity()
func _get_verbosity() -> Verbosity:
	return Verbosity.USER_FACING


## Defines whether or not this statement can be used as a stop point when rolling back. Usually true for any statement that pauses execution until user manually inputs.
var is_rollable_back : bool :
	get: return _get_is_rollable_back()
func _get_is_rollable_back() -> bool:
	return false

var is_rollable_ahead : bool :
	get: return _get_is_rollable_ahead()
func _get_is_rollable_ahead() -> bool:
	return _get_is_rollable_back()

## Defines whether or not this statement can be automatically skipped. This should be false for any stmt that both (1) relies on user input AND (2) alters the stmt flow. E.g. menus/prompts. True for all others.
var is_skippable : bool :
	get: return _get_is_skippable()
func _get_is_skippable() -> bool:
	return true


var is_loadable : bool :
	get: return _get_is_loadable()
func _get_is_loadable() -> bool:
	return false


func _to_string() -> String:
	return _debug_string_do_not_use_for_anything_else_seriously_i_mean_it


## Called after the statement is created.
func populate(_owner : PennyScript, _index : int, tokens : Array) -> void:
	tokens = tokens.duplicate()

	for i in tokens:
		hash_id += hash(i.value)

	owner = _owner
	index = _index
	depth = tokens.pop_front().value if (tokens and tokens[0].type == PennyScript.Token.Type.INDENTATION) else 0


	if OS.is_debug_build():
		var _d : String = ""
		for token in tokens:
			_d += token.to_string().split(":")[1] + " "
		_debug_string_do_not_use_for_anything_else_seriously_i_mean_it = ">\t".repeat(depth + 1) + _d.substr(0, _d.length() - 1)

	index_in_same_depth_chain = get_index_in_same_depth_chain()
	context_ref = get_context_ref()
func _populate(tokens: Array) -> void: pass


func populate_from_other(other: Stmt, tokens : Array) -> void:
	hash_id = other.hash_id
	owner = other.owner
	index = other.index
	depth = other.depth
	_debug_string_do_not_use_for_anything_else_seriously_i_mean_it = other._debug_string_do_not_use_for_anything_else_seriously_i_mean_it

	index_in_same_depth_chain = other.index_in_same_depth_chain
	context_ref = other.context_ref

	self._populate(tokens)


## Called when Penny reloads all scripts. If any errors are produced, add them to [member script]'s error list.
func reload() -> void:
	prev_in_order = 				get_prev_in_order()
	prev_in_same_depth = 			get_prev_in_same_depth()
	prev_in_same_or_lower_depth = 	get_prev_in_same_or_lower_depth()
	prev_in_lower_depth = 			get_prev_in_lower_depth()
	prev_in_higher_depth = 			get_prev_in_higher_depth()
	next_in_order = 				get_next_in_order()
	next_in_same_depth = 			get_next_in_same_depth()
	next_in_same_or_lower_depth = 	get_next_in_same_or_lower_depth()
	next_in_lower_depth = 			get_next_in_lower_depth()
	next_in_higher_depth = 			get_next_in_higher_depth()

	self._reload()
func _reload() -> void: pass


## Perform calculations before execution and creates/initializes a record. Not awaitable and doesn't happen on redo.
func prep(host: PennyHost, data: Dictionary = {}) -> Record:
	var result := Record.new(host, self, data)
	_prep(result)
	return result
func _prep(record: Record) -> void: pass


## Given a record, waits for something to complete BEFORE calling the next [Stmt]
func execute(record: Record) :
	var result = await Async.any([
		self._execute.bind(record),
		self.aborted,
	])
	await _cleanup(record)
	return result
func _execute(record: Record) : pass
## Perform cleanup actions regardless of how the execution finished.
func _cleanup(record: Record) : pass


## Occurs when something interrupts this [Stmt] in the middle of execution.
func abort() -> void:
	_abort()
	aborted.emit()
func _abort() -> void : pass


## Occurs when the user rewinds through history to undo this action.
func undo(record: Record) -> void: _undo(record)
func _undo(record: Record) -> void:	pass


## Occurs when the user fast-forwards through history to redo this action.
func redo(record: Record) -> void: _redo(record)
func _redo(record: Record) -> void: pass


## Returns the address of the next statement to go to, based on what happened.
func next(record: Record) -> Stmt: return _next(record)
func _next(record: Record) -> Stmt:
	return next_in_order


func create_history_listing(record: Record) -> HistoryListing: return _create_history_listing(record)
func _create_history_listing(record: Record) -> HistoryListing:
	var result : HistoryListing = load("res://addons/penny_godot/assets/scenes/history_listings/history_listing_default.tscn").instantiate()
	result.populate(record)
	return result


func get_record_message(record: Record) -> String: return _get_record_message(record)
func _get_record_message(record: Record) -> String:
	return "[code][color=deep_pink]Unimplemented Stmt %s[/color][/code]" % self


func export_json() -> Dictionary:
	var result := {
		&"idx": index,
		&"uid": ResourceUID.id_to_text(ResourceLoader.get_resource_uid(owner.resource_path)),
	}
	if OS.is_debug_build():
		result.merge({
			&"__debug_script__": owner.resource_path,
			&"__debug_string__": _debug_string_do_not_use_for_anything_else_seriously_i_mean_it,
		})
	return result

#region Addresses

func get_next_in_order() -> Stmt :
	var i := self.index + 1
	if i >= owner.stmts.size():
		return null
	return owner.stmts[i]


func get_next_in_same_depth() -> Stmt :
	var cursor := self.get_next_in_order()
	while cursor:
		if cursor.depth == self.depth:
			return cursor
		if cursor.depth < self.depth:
			break
		cursor = cursor.get_next_in_order()
	return null


func get_next_in_same_or_lower_depth() -> Stmt :
	var cursor := self.get_next_in_order()
	while cursor:
		if cursor.depth <= self.depth:
			return cursor
		cursor = cursor.get_next_in_order()
	return null


func get_next_in_lower_depth() -> Stmt :
	if self.depth == 0:
		return null

	var cursor := self.get_next_in_order()
	while cursor:
		if cursor.depth < self.depth:
			return cursor
		cursor = cursor.get_next_in_order()
	return null


func get_next_in_higher_depth() -> Stmt :
	var cursor := self.get_next_in_order()
	while cursor:
		if cursor.depth > self.depth:
			return cursor
		cursor = cursor.get_next_in_order()
	return null


func get_prev_in_order() -> Stmt :
	var i := self.index - 1
	if i < 0:
		return null
	return owner.stmts[i]


func get_prev_in_same_depth() -> Stmt :
	var cursor := self.get_prev_in_order()
	while cursor:
		if cursor.depth == self.depth:
			return cursor
		if cursor.depth < self.depth:
			break
		cursor = cursor.get_prev_in_order()
	return null


func get_prev_in_same_or_lower_depth() -> Stmt :
	var cursor := self.get_prev_in_order()
	while cursor:
		if cursor.depth <= self.depth:
			return cursor
		cursor = cursor.get_prev_in_order()
	return null


func get_prev_in_lower_depth() -> Stmt :
	if self.depth == 0:
		return null

	var cursor := self.get_prev_in_order()
	while cursor:
		if cursor.depth < self.depth:
			return cursor
		cursor = cursor.get_prev_in_order()
	return null


func get_prev_in_higher_depth() -> Stmt :
	var cursor := self.get_prev_in_order()
	while cursor:
		if cursor.depth > self.depth:
			return cursor
		cursor = cursor.get_prev_in_order()
	return null


func get_index_in_same_depth_chain() -> int:
	var cursor := self.get_prev_in_same_depth()
	return cursor.index_in_same_depth_chain + 1 if cursor else 0


func get_context_ref() -> Path:
	var cursor := self.get_prev_in_lower_depth()
	var _ids : PackedStringArray
	while cursor:
		if cursor is StmtCell: for i in cursor.local_subject_ref.ids.size():
			_ids.insert(0, cursor.local_subject_ref.ids[-i - 1])
		cursor = cursor.get_prev_in_lower_depth()
	return Path.new(_ids, false)


func get_nested_stmts_single_depth() -> Array[Stmt] :
	var cursor := self.get_next_in_higher_depth()
	var result : Array[Stmt]
	while cursor:
		result.push_back(cursor)
		cursor = cursor.get_next_in_same_depth()
	return result

#endregion
