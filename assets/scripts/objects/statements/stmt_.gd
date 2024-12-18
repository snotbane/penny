
@tool
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

signal aborted(record: Record)

var hash_id : int
var owning_script : PennyScript
var index_in_script : int
var file_address : FileAddress
var index_in_file : int
var nest_depth : int
var tokens : Array[Token]


var keyword : StringName :
	get: return _get_keyword()
## Helper keyword to define what this statement does.
func _get_keyword() -> StringName:
	return 'INVALID'


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


var line_string : String :
	get: return "ln %s" % index_in_file


var depth_string : String :
	get: return "dp %s" % nest_depth


var owning_object : PennyObject :
	get:
		var result : PennyObject = owning_object_path.evaluate()
		if result : return result
		else : return PennyObject.STATIC_ROOT


var next_in_order : Stmt :
	get:
		var i := self.index_in_script + 1
		if i >= owning_script.stmts.size():
			return null
		return owning_script.stmts[i]


var next_in_same_depth : Stmt :
	get:
		var cursor := self.next_in_order
		while cursor:
			if cursor.nest_depth == self.nest_depth:
				return cursor
			if cursor.nest_depth < self.nest_depth:
				break
			cursor = cursor.next_in_order
		return null


var next_in_same_or_lower_depth : Stmt :
	get:
		var cursor := self.next_in_order
		while cursor:
			if cursor.nest_depth <= self.nest_depth:
				return cursor
			cursor = cursor.next_in_order
		return null


var next_in_lower_depth : Stmt :
	get:
		if self.nest_depth == 0:
			return null

		var cursor := self.next_in_order
		while cursor:
			if cursor.nest_depth < self.nest_depth:
				return cursor
			cursor = cursor.next_in_order
		return null


var next_in_higher_depth : Stmt :
	get:
		var cursor := self.next_in_order
		while cursor:
			if cursor.nest_depth > self.nest_depth:
				return cursor
			cursor = cursor.next_in_order
		return null


var prev_in_order : Stmt :
	get:
		var i := self.index_in_script - 1
		if i < 0:
			return null
		return owning_script.stmts[i]


var prev_in_same_depth : Stmt :
	get:
		var cursor := self.prev_in_order
		while cursor:
			if cursor.nest_depth == self.nest_depth:
				return cursor
			if cursor.nest_depth < self.nest_depth:
				break
			cursor = cursor.prev_in_order
		return null


var prev_in_same_or_lower_depth : Stmt :
	get:
		var cursor := self.prev_in_order
		while cursor:
			if cursor.nest_depth <= self.nest_depth:
				return cursor
			cursor = cursor.prev_in_order
		return null


var prev_in_lower_depth : Stmt :
	get:
		if self.nest_depth == 0:
			return null

		var cursor := self.prev_in_order
		while cursor:
			if cursor.nest_depth < self.nest_depth:
				return cursor
			cursor = cursor.prev_in_order
		return null


var prev_in_higher_depth : Stmt :
	get:
		var cursor := self.prev_in_order
		while cursor:
			if cursor.nest_depth > self.nest_depth:
				return cursor
			cursor = cursor.prev_in_order
		return null


var owning_object_stmt : StmtObject :
	get:
		var result := self.prev_in_lower_depth
		if result:
			if result is StmtObject:
				return result
			else:
				return result.owning_object_stmt
		return null


var owning_object_path : Path :
	get:
		var cursor := self
		var result := Path.new([], true)
		while result.relative:
			cursor = cursor.prev_in_lower_depth
			if not cursor:
				result.relative = false
				break
			if cursor is StmtObject:
				result.prepend(cursor.path)
		return result


var nested_stmts_single_depth : Array[Stmt] :
	get:
		var cursor := self.next_in_higher_depth
		var result : Array[Stmt]
		while cursor:
			result.push_back(cursor)
			cursor = cursor.next_in_same_depth
		return result


var index_in_same_depth_chain : int:
	get:
		var cursor := self.prev_in_same_depth
		var result := 0
		while cursor:
			result += 1
			cursor = cursor.prev_in_same_depth
		return result


var debug_string : String :
	get:
		var result := self.keyword
		for i in tokens:
			result += " " + str(i.value)
		return result


func get_path_relative_to_here(path: Path) -> Path:
	var result : Path = path.duplicate()
	if path.relative:
		var root : Path = owning_object_path
		if root:
			result.prepend(root)
		result.relative = false
	return result


func get_value_from_path_relative_to_here(context: PennyObject, path: Path) -> Variant:
	return get_path_relative_to_here(path).evaluate(context)


func populate(_owning_script: PennyScript, _index_in_script: int, _index_in_file: int, _depth: int, _tokens: Array[Token]) -> void:
	self.owning_script = _owning_script
	self.index_in_script = _index_in_script
	self.index_in_file = _index_in_file
	self.nest_depth = _depth
	self.tokens = _tokens
	self.hash_id = hash(self.debug_string)


func populate_from_other(other: Stmt) -> void:
	self.populate(other.owning_script, other.index_in_script, other.index_in_file, other.nest_depth, other.tokens)


func _to_string() -> String:
	return "%s %s : %s %s" % [line_string, depth_string, _get_keyword(), debug_string]


## Called once to check this statement has all its pieces in the proper places. Penny can't run unless EVERY STATEMENT IN ALL SCRIPTS are successfully validated. Return null to indicate success.
func validate_self() -> PennyException: return _validate_self()
## Called once to check this statement has all its pieces in the proper places. Penny can't run unless EVERY STATEMENT IN ALL SCRIPTS are successfully validated. Return null to indicate success.
func _validate_self() -> PennyException:
	return create_exception("Stmt was never recycled; probably needs new Stmt class or registration.")


## Called once after THIS script has been successfully validated (after [member validate_self], before [member load]). Use to initialize data for this script. Effectively an extension of [member validate_self].
func validate_self_post_setup() -> void: _validate_self_post_setup()
## Called once after THIS script has been successfully validated (after [member validate_self], before [member load]). Use to initialize data for this script. Effectively an extension of [member validate_self].
func _validate_self_post_setup() -> void:
	pass


## Called once, after ALL scripts have been successfully validated (after [member validate_self_post_setup]). Use to initialize date between scripts.
func validate_cross() -> PennyException: return _validate_cross()
## Called once, after ALL scripts have been successfully validated (after [member validate_self_post_setup]). Use to initialize date between scripts.
func _validate_cross() -> PennyException:
	return null


## Executes when it is reached as the user encounters it.
func execute(host: PennyHost) :
	return await Async.any([self._execute.bind(host), self.aborted])
## Executes when it is reached as the user encounters it.
func _execute(host: PennyHost) :
	return self.create_record(host)


func abort(host : PennyHost, response : Record.Response) -> void:
	var record := self._abort(host)
	record.response = response
	self.aborted.emit(record)
func _abort(host : PennyHost) -> Record :
	return self.create_record(host, null)


## Executes when the user rewinds through history to undo this action.
func undo(record: Record) -> void: _undo(record)
## Executes when the user rewinds through history to undo this action.
func _undo(record: Record) -> void:	pass


## Executes when the user fast-forwards through history to redo this action.
func redo(record: Record) -> void: _redo(record)
## Executes when the user fast-forwards through history to redo this action.
func _redo(record: Record) -> void: _execute(record.host)


## Returns the address of the next statement to go to, based on what happened.
func next(record: Record) -> Stmt: return _next(record)
## Returns the address of the next statement to go to, based on what happened.
func _next(record: Record) -> Stmt:
	return next_in_order


func _get_history_listing_scene() -> PackedScene :
	return load("res://addons/penny_godot/assets/scenes/history_listings/history_listing_default.tscn")


func create_history_listing(record: Record) -> HistoryListing: return _create_history_listing(record)
func _create_history_listing(record: Record) -> HistoryListing:
	var result : HistoryListing = _get_history_listing_scene().instantiate()
	result.populate(record)
	return result


func get_record_message(record: Record) -> String: return _get_record_message(record)
func _get_record_message(record: Record) -> String:
	var result := "[code][color=#a030a0ff]%s[/color] [/code]" % self.keyword
	for i in tokens:
		result += " " + str(i.value)
	return result


func create_record(host: PennyHost, data: Variant = null) -> Record:
	return Record.new(host, self, data)


func save_data() -> Variant:
	var result := {
		"index": index_in_script,
		"script": owning_script.resource_path,
	}
	if OS.is_debug_build():
		result.merge({
			"string": debug_string
		})
	return result


func create_exception(s: String = "Uncaught exception.") -> PennyException:
	return PennyExceptionRef.new(file_address, s)


func push_exception(s: String = "Uncaught exception.") -> PennyException:
	var result := PennyExceptionRef.new(file_address, s)
	result.push_error()
	return result


func push_warn(s:String = "Uncaught exception.") -> PennyException:
	var result := PennyExceptionRef.new(file_address, s)
	result.push_warn()
	return result


func recycle() -> Stmt:
	var result := get_recycle_typed_version()
	result.populate_from_other(self)
	return result


func get_recycle_typed_version() -> Stmt:
	for i in tokens:
		match i.type:
			Token.ASSIGNMENT:
				return StmtAssign.new()
	match tokens.front().type:
		Token.KEYWORD:
			var key = tokens.pop_front().value
			match key:
				'call': 	return StmtJumpCall.new()
				'close': 	return StmtClose.new()
				'else': 	return StmtConditionalElse.new()
				'elif': 	return StmtConditionalElif.new()
				'if': 		return StmtConditionalIf.new()
				'init':		return StmtInit.new()
				'jump': 	return StmtJump.new()
				'label': 	return StmtLabel.new()
				'match': 	return StmtMatch.new()
				'menu': 	return StmtMenu.new()
				'open': 	return StmtOpen.new()
				'pass': 	return StmtPass.new()
				'print': 	return StmtPrint.new()
				'return':	return StmtReturn.new()
				'await':	return StmtAwait.new()
			PennyException.new("The keyword '%s' was detected, but no method is registered for it in Stmt.recycle()." % key).push_error()
			return self

	var block_header := self.prev_in_lower_depth
	if block_header:
		if block_header is StmtMatch:
			return StmtConditionalMatch.new()
		elif block_header is StmtMenu:
			return StmtConditionalMenu.new()

	match tokens.back().type:
			Token.VALUE_STRING:
				return StmtDialog.new()
	match tokens.front().type:
		Token.IDENTIFIER:
			if tokens.size() == 1 or tokens[1].value == '.':
				return StmtObject.new()
		Token.OPERATOR:
			if tokens[0].value == '.' and tokens[1].type == Token.IDENTIFIER:
				return StmtObject.new()
	return self


func validate_as_no_tokens() -> PennyException:
	if not tokens.is_empty():
		return create_exception("Unexpected token(s) in standalone statement.")
	return null


func validate_path(expr: Array[Token]) -> PennyException:
	var relative : bool = expr[0].value == '.'
	if expr.back().type != Token.IDENTIFIER:
		return create_exception("Expected identifier at end of path.")
	for i in expr.size():
		var token := expr[i]
		if bool(i & 1) == relative:
			if token.type != Token.IDENTIFIER:
				return create_exception("Expected identifier in path.")
		else:
			if token.value != '.':
				return create_exception("Expected dot operator in path.")
	return null


func validate_as_identifier_only() -> PennyException:
	if tokens.size() != 1:
		return create_exception("Statement requires exactly 1 token.")
	if tokens[0].type != Token.IDENTIFIER:
		return create_exception("Unexpected token '%s' is not an identifier." % tokens[0])
	return null


func validate_as_lookup() -> PennyException:
	return null


func validate_as_expression(require: bool = true) -> PennyException:
	if not require and tokens.is_empty():
		return null
	return validate_expression(tokens)


func validate_expression(expr: Array[Token]) -> PennyException:
	if expr.is_empty():
		return create_exception("Expression is empty.")
	return null
