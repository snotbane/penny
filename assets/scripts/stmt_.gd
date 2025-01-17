
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

signal aborted(record: Record)

var owner : PennyScript
var index : int
var depth : int

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


var verbosity : int :
	get: return _get_verbosity()
## Defines whether or not this statement should show up in history. -1 = always show, even to end user. Values greater than 0 are used for debugging purposes.
func _get_verbosity() -> Verbosity:
	return Verbosity.USER_FACING


var is_rollable : bool :
	get: return _get_is_rollable()
## Defines whether or not this statement can be used as a stop point when rolling back or forward. Usually true for any statement that pauses execution until user manually inputs.
func _get_is_rollable() -> bool:
	return false


var is_skippable : bool :
	get: return _get_is_skippable()
## Defines whether or not this statement can be automatically skipped. This should be false for any stmt that both (1) relies on user input AND (2) alters the stmt flow. E.g. menus/prompts. True for all others.
func _get_is_skippable() -> bool:
	return true

## Called after the statement is created.
func populate(_owner : PennyScript, _index : int, tokens : Array) -> void:
	owner = _owner
	index = _index
	depth = tokens[0].value.length() if (tokens and tokens[0].type == PennyScript.Token.Type.INDENTATION) else 0

	self._populate(tokens)
func _populate(tokens: Array) -> void: pass


## Called when Penny reloads all scripts. If any errors are produced, add them to [member script]'s error list.
func reload() -> void:
	prev_in_order = get_prev_in_order()
	prev_in_same_depth = get_prev_in_same_depth()
	prev_in_same_or_lower_depth = get_prev_in_same_or_lower_depth()
	prev_in_lower_depth = get_prev_in_lower_depth()
	prev_in_higher_depth = get_prev_in_higher_depth()
	next_in_order = get_next_in_order()
	next_in_same_depth = get_next_in_same_depth()
	next_in_same_or_lower_depth = get_next_in_same_or_lower_depth()
	next_in_lower_depth = get_next_in_lower_depth()
	next_in_higher_depth = get_next_in_higher_depth()

	self._reload()
func _reload() -> void: pass

## Occurs when it is reached as a [PennyController] encounters it.
func execute(host: PennyHost) :
	return await Async.any([self._execute.bind(host), self.aborted])
func _execute(host: PennyHost) :
	return self.create_record(host)


## Occurs when something interrupts this [Stmt] in the middle of execution.
func abort(host : PennyHost, response : Record.Response) -> void:
	var record := self._abort(host)
	record.response = response
	self.aborted.emit(record)
func _abort(host : PennyHost) -> Record :
	return self.create_record(host, null)


## Occurs when the user rewinds through history to undo this action.
func undo(record: Record) -> void: _undo(record)
func _undo(record: Record) -> void:	pass


## Occurs when the user fast-forwards through history to redo this action.
func redo(record: Record) -> void: _redo(record)
func _redo(record: Record) -> void: _execute(record.host)


## Returns the address of the next statement to go to, based on what happened.
func next(record: Record) -> Stmt: return _next(record)
func _next(record: Record) -> Stmt:
	return next_in_order


func create_record(host: PennyHost, data: Variant = null) -> Record:
	return Record.new(host, self, data)


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
