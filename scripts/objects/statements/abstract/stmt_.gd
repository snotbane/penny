
@tool
class_name Stmt_ extends RefCounted

## Location of a Statement specified by a file path and array index.
class Address extends RefCounted:

	var path : StringName
	var file_index : int
	var index : int

	var stmt : Stmt_ :
		get:
			if valid:
				return Penny.scripts[file_index].stmts[index]
			return null

	var valid : bool :
		get:
			if file_index < Penny.scripts.size():
				return index >= 0 and index < Penny.scripts[file_index].stmts.size()
			return false

	func _init(_file_index: int, __index: int) -> void:
		file_index = _file_index
		index = __index

	func copy(offset: int = 0) -> Address:
		return Address.new(file_index, index + offset)

	func hash() -> int:
		return path.hash() + hash(index)

	func equals(other: Address) -> bool:
		return self.hash() == other.hash()

	func _to_string() -> String:
		return "%s:%s (ln %s)" % [path, index, stmt.line]



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

var address : Address
var file_address : FileAddress
var line : int
var depth : int
var tokens : Array[Token]

var verbosity : int :
	get: return _get_verbosity()

var keyword : StringName :
	get: return _get_keyword()

var line_string : String :
	get: return "ln %s" % line

var depth_string : String :
	get: return "dp %s" % depth

## The next statement in order, regardless of depth.
var next_in_order : Stmt_ :
	get: return address.copy(1).stmt

var next_in_same_depth : Stmt_ :
	get:
		var cursor := address.copy(1)
		while true:
			if cursor.stmt.depth == depth:
				return cursor.stmt
			if not cursor.valid or cursor.stmt.depth < depth:
				return null
			cursor.index += 1
		return null

var next_in_same_or_lower_depth : Stmt_ :
	get:
		var cursor := address.copy(1)
		while cursor.valid:
			if cursor.stmt.depth <= depth:
				return cursor.stmt
			cursor.index += 1
		return null

var next_in_lower_depth : Stmt_ :
	get:
		if depth == 0: return null
		var cursor := address.copy(1)
		while cursor.valid:
			if cursor.stmt.depth < depth:
				return cursor.stmt
			cursor.index += 1
		return null

var next_in_higher_depth : Stmt_ :
	get:
		var cursor := address.copy(1)
		while cursor.valid:
			if cursor.stmt.depth > depth:
				return cursor.stmt
			cursor.index += 1
		return null

var next_nested_block : Array[Stmt_] :
	get:
		var cursor := address.copy(1)
		if cursor.stmt.depth <= depth:
			return []
		var result : Array[Stmt_] = []
		while cursor and cursor.valid:
			result.push_back(cursor)
			cursor = cursor.stmt.next_in_same_depth.address.copy()
		return result

var prev_in_order : Stmt_ :
	get: return address.copy(-1).stmt

## The previous statement in the exact same depth as this one. If we ever exit this depth (lower), return null (start of chain).
var prev_in_same_depth : Stmt_ :
	get:
		var cursor := address.copy(-1)
		while cursor.valid:
			if cursor.stmt.depth == depth:
				return cursor.stmt
			if cursor.stmt.depth < depth:
				return null
			cursor.index -= 1
		return null

## The previous statement in the same depth (or lower) as this one.
var prev_in_same_or_lower_depth : Stmt_ :
	get:
		var cursor := address.copy(-1)
		while cursor.valid:
			if cursor.stmt.depth <= depth:
				return cursor.stmt
			cursor.index -= 1
		return null

## The previous statement in a lower depth than this one. (less nested)
var prev_in_lower_depth : Stmt_ :
	get:
		if depth == 0: return null
		var cursor := address.copy(-1)
		while cursor.valid:
			if cursor.stmt.depth < depth:
				return cursor.stmt
			cursor.index -= 1
		return null

## The previous statement in a higher depth than this one. (more nested)
var prev_in_higher_depth : Stmt_ :
	get:
		var cursor := address.copy(-1)
		while cursor.valid:
			if cursor.stmt.depth > depth:
				return cursor.stmt
			cursor.index -= 1
		return null

var owning_object_stmt : StmtObject_ :
	get:
		var result := prev_in_lower_depth
		if result:
			if result is StmtObject_:
				return result
			else:
				return result.owning_object_stmt
		return null


var owning_object_path : Path :
	get:
		var stmt := self
		var result := Path.new([], true)
		while result.relative:
			stmt = stmt.prev_in_lower_depth
			if not stmt:
				result.relative = false
				break
			if stmt is StmtObject_:
				result.prepend(stmt.path)
		return result


var reconstructed_string : String :
	get:
		var result := ""
		for i in tokens:
			result += str(i.value) + " "
		result = result.substr(0, result.length() - 1)
		return result


func get_path_relative_to_here(path: Path) -> Path:
	var result : Path = path.duplicate()
	if path.relative:
		var root : Path = owning_object_path
		if root:
			result.prepend(root)
		result.relative = false
	return result


## Returns the object which this statement refers to.
func get_owning_object(context: PennyObject) -> PennyObject:
	return owning_object_path.evaluate(context)


## Returns the value at the path with some starting point [root]
func get_value_from_path_relative_to_here(context: PennyObject, path: Path) -> Variant:
	return get_path_relative_to_here(path).evaluate(context)


func populate(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	self.address = _address
	self.depth = _depth
	self.line = _line
	self.tokens = _tokens


func populate_from_other(other: Stmt_) -> void:
	self.populate(other.address.copy(), other.depth, other.line, other.tokens.duplicate(true))


func _to_string() -> String:
	return "%s %s : %s %s" % [line_string, depth_string, _get_keyword(), reconstructed_string]


## Helper keyword to define what this statement does.
func _get_keyword() -> StringName:
	return 'INVALID'


## Defines whether or not this statement should show up in history. -1 = always show, even to end user. Values greater than 0 are used for debugging purposes.
func _get_verbosity() -> Verbosity:
	return Verbosity.USER_FACING


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
func execute(host: PennyHost) -> Record: return _execute(host)
## Executes when it is reached as the user encounters it.
func _execute(host: PennyHost) -> Record:
	return create_record(host)


## Executes when the user rewinds through history to undo this action.
func undo(record: Record) -> void: _undo(record)
## Executes when the user rewinds through history to undo this action.
func _undo(record: Record) -> void:
	pass


## Returns the address of the next statement to go to, based on what happened.
func next(record: Record) -> Stmt_: return _next(record)
## Returns the address of the next statement to go to, based on what happened.
func _next(record: Record) -> Stmt_:
	return next_in_order


## Creates a message to be shown in the statement history or displayed to a dialogue box.
func message(record: Record) -> Message: return _message(record)
## Creates a message to be shown in the statement history or displayed to a dialogue box.
func _message(record: Record) -> Message:
	return Message.new(reconstructed_string)


func create_history_node(record: Record) -> Control: return _create_history_node(record)
func _create_history_node(record: Record) -> Control:
	return null


func create_record(host: PennyHost, halt: bool = false, attachment: Variant = null) -> Record:
	return Record.new(host, self, halt, attachment)


func create_exception(s: String = "Uncaught exception.") -> PennyException:
	return PennyExceptionRef.new(file_address, s)


func push_exception(s: String = "Uncaught exception.") -> PennyException:
	var result := PennyExceptionRef.new(file_address, s)
	result.push()
	return result


func recycle() -> Stmt_:
	var result := get_recycle_typed_version()
	result.populate_from_other(self)
	return result


func get_recycle_typed_version() -> Stmt_:
	for i in tokens:
		match i.type:
			Token.ASSIGNMENT:
				return StmtAssign.new()
			Token.KEYWORD:
				if tokens.size() == 1 and tokens[0].value == 'object':
					return StmtObject_.new()
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
				'open': 	return StmtOpen.new()
				'pass': 	return StmtPass.new()
				'print': 	return StmtPrint.new()
				'return':	return StmtReturn.new()
			PennyException.new("The keyword '%s' was detected, but no method is registered for it in Stmt_.recycle()." % key).push()
			return self
	match tokens.back().type:
			Token.VALUE_STRING:
				return StmtDialog.new()
	match tokens.front().type:
		Token.IDENTIFIER:
			if tokens.size() == 1 or tokens[1].value == '.':
				return StmtObject_.new()
		Token.OPERATOR:
			if tokens[0].value == '.' and tokens[1].type == Token.IDENTIFIER:
				return StmtObject_.new()
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
