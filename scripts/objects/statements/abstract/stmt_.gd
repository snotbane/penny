
@tool
class_name Stmt_ extends RefCounted

## Location of a Statement specified by a file path and array index.
class Address extends RefCounted:

	var path : StringName

	var index : int

	var stmt : Stmt_ :
		get:
			if valid:
				return Penny.stmt_dict[path][index]
			return null

	var valid : bool :
		get:
			if Penny.stmt_dict.has(path):
				return index >= 0 and index < Penny.stmt_dict[path].size()
			return false

	func _init(__path: StringName, __index: int) -> void:
		path = __path
		index = __index

	func copy(offset: int = 0) -> Address:
		return Address.new(path, index + offset)

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

var is_halting : bool :
	get: return _get_is_halting()

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

## The next statement in the exact same depth as this one. If we ever exit this depth (lower), return null (end of chain).
var next_in_chain : Stmt_ :
	get:
		var cursor := address.copy(1)
		while true:
			if cursor.stmt.depth == depth:
				return cursor.stmt
			if not cursor.valid or cursor.stmt.depth < depth:
				return null
			cursor.index += 1
		return null

## The next statement in the same depth (or lower) as this one.
var next_in_depth : Stmt_ :
	get:
		var cursor := address.copy(1)
		while cursor.valid:
			if cursor.stmt.depth <= depth:
				return cursor.stmt
			cursor.index += 1
		return null

## The next statement in a lower depth than this one. (less nested)
var next_lower_depth : Stmt_ :
	get:
		if depth == 0: return null
		var cursor := address.copy(1)
		while cursor.valid:
			if cursor.stmt.depth < depth:
				return cursor.stmt
			cursor.index += 1
		return null

## The next statement in a higher depth than this one. (more nested)
var next_higher_depth : Stmt_ :
	get:
		var cursor := address.copy(1)
		while cursor.valid:
			if cursor.stmt.depth > depth:
				return cursor.stmt
			cursor.index += 1
		return null

## Returns all statements exactly one depth higher than this one. (more nested)
var next_higher_chain : Array[Stmt_] :
	get:
		var cursor := address.copy(1)
		if cursor.stmt.depth <= depth:
			return []
		var result : Array[Stmt_] = []
		while cursor and cursor.valid:
			result.push_back(cursor)
			cursor = cursor.stmt.next_in_chain.address.copy()
		return result

## The previous statement in order, regardless of depth.
var prev_in_order : Stmt_ :
	get: return address.copy(-1).stmt

## The previous statement in the exact same depth as this one. If we ever exit this depth (lower), return null (start of chain).
var prev_in_chain : Stmt_ :
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
var prev_in_depth : Stmt_ :
	get:
		var cursor := address.copy(-1)
		while cursor.valid:
			if cursor.stmt.depth <= depth:
				return cursor.stmt
			cursor.index -= 1
		return null

## The previous statement in a lower depth than this one. (less nested)
var prev_lower_depth : Stmt_ :
	get:
		if depth == 0: return null
		var cursor := address.copy(-1)
		while cursor.valid:
			if cursor.stmt.depth < depth:
				return cursor.stmt
			cursor.index -= 1
		return null

## The previous statement in a higher depth than this one. (more nested)
var prev_higher_depth : Stmt_ :
	get:
		var cursor := address.copy(-1)
		while cursor.valid:
			if cursor.stmt.depth > depth:
				return cursor.stmt
			cursor.index -= 1
		return null

var nested_object_stmt : StmtObject_ :
	get:
		var result := prev_lower_depth
		if result:
			if result is StmtObject_:
				return result
			else:
				return result.nested_object_stmt
		return null


## Returns the object [Path] under which this [Stmt_] is nested.
var nested_object_path : Path :
	get:
		var stmt := self
		var result := Path.new()
		while stmt:
			stmt = stmt.prev_lower_depth
			if stmt is StmtObject_:
				result.prepend(stmt.path)
		return result


var reconstructed_string : String :
	get:
		var result := ""
		for i in tokens:
			result += str(i.value) + " "
		result = result.substr(0, result.length() - 1)
		return "%s %s" % [_get_keyword(), result]


func get_full_path(path: Path) -> Path:
	var result : Path = path.duplicate()
	if path.relative:
		var root : Path = nested_object_path
		if root:
			result.prepend(root)
		result.relative = false
	return result


func get_nested_object(root: PennyObject) -> PennyObject:
	return get_full_path(nested_object_path).get_deep_value_for(root)


func get_value_from_path(root: PennyObject, path: Path) -> Variant:
	return get_full_path(path).get_deep_value_for(root)


func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	address = _address
	depth = _depth
	line = _line
	tokens = _tokens

func _to_string() -> String:
	return "%s %s : %s" % [line_string, depth_string, reconstructed_string]

## Whether or not this statement should pause the execution flow, for an indeterminate amount of time.
func _get_is_halting() -> bool:
	return false

## Helper keyword to define what this statement does.
func _get_keyword() -> StringName:
	return 'INVALID'

## Defines whether or not this statement should show up in history. -1 = always show, even to end user. Values greater than 0 are used for debugging purposes.
func _get_verbosity() -> Verbosity:
	return Verbosity.USER_FACING

func is_record_shown_in_history(record: Record) -> bool: return _is_record_shown_in_history(record)
func _is_record_shown_in_history(record: Record) -> bool:
	return true

## Executes just once, as soon as all scripts have been validated.
func load() -> PennyException: return _load()
func _load() -> PennyException:
	return null

## Executes when it is reached as the user encounters it.
func execute(host: PennyHost) -> Record: return _execute(host)
func _execute(host: PennyHost) -> Record:
	return Record.new(host, self)

## Executes when the user rewinds through history to undo this action.
func undo(record: Record) -> void: _undo(record)
func _undo(record: Record) -> void:
	pass

## Returns the address of the next statement to go to, based on what happened.
func next(record: Record) -> Stmt_: return _next(record)
func _next(record: Record) -> Stmt_:
	return next_in_order

## Creates a message to be shown in the statement history or displayed to a dialogue box.
func message(record: Record) -> Message: return _message(record)
func _message(record: Record) -> Message:
	return Message.new(reconstructed_string)

func create_history_node(record: Record) -> Control: return _create_history_node(record)
func _create_history_node(record: Record) -> Control:
	return null

## Returns an exception to check what may be wrong with the statement (or null if OK)
func validate() -> PennyException: return _validate()
func _validate() -> PennyException:
	return create_exception("_validate() method needs to be overridden and/or statement was never recycled into the proper type (not implemented).")

func setup() -> void: _setup()
func _setup() -> void:
	pass

func create_exception(s: String = "Uncaught exception.") -> PennyException:
	return PennyExceptionRef.new(file_address, s)

func recycle() -> Stmt_:
	if tokens.is_empty():
		create_exception("Empty statement.")
	for i in tokens:
		match i.type:
			Token.ASSIGNMENT:
				return StmtAssign.new(address, line, depth, tokens)
			Token.KEYWORD:
				if tokens.size() == 1 and tokens[0].value == 'object':
					return StmtObject_.new(address, line, depth, tokens)
	match tokens[0].type:
		Token.VALUE_STRING:
			return StmtMessage.new(address, line, depth, tokens)
		Token.KEYWORD:
			var key = tokens.pop_front().value
			match key:
				'call': return StmtJumpCall.new(address, line, depth, tokens)
				'else': return StmtConditionalElse.new(address, line, depth, tokens)
				'elif': return StmtConditionalElif.new(address, line, depth, tokens)
				'if': return StmtConditionalIf.new(address, line, depth, tokens)
				'jump': return StmtJump.new(address, line, depth, tokens)
				'label': return StmtLabel.new(address, line, depth, tokens)
				'open': return StmtNode_.new(address, line, depth, tokens)
				'pass': return StmtPass.new(address, line, depth, tokens)
				'print': return StmtPrint.new(address, line, depth, tokens)
		Token.IDENTIFIER:
			if tokens.size() == 1 or tokens[1].value == '.':
				return StmtObject_.new(address, line, depth, tokens)
		Token.OPERATOR:
			if tokens[0].value == '.' and tokens[1].type == Token.IDENTIFIER:
				return StmtObject_.new(address, line, depth, tokens)
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
