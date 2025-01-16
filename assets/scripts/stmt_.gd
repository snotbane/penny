
## Base class for all executable statemetnts.
class_name Stmt extends RefCounted

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
