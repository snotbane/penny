
@tool
class_name Stmt extends RefCounted

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
var next_in_order : Stmt :
	get: return address.copy(1).stmt

## Next statement in the exact same depth as this one. If we ever exit this depth (lower), return null (end of chain).
var next_in_chain : Stmt :
	get:
		var cursor := address.copy(1)
		while cursor.valid:
			if cursor.stmt.depth == depth:
				break
			if cursor.stmt.depth < depth:
				return null
			cursor.index += 1
		return cursor.stmt

## The next statement in the same depth (or lower) as this one.
var next_in_depth : Stmt :
	get:
		var cursor := address.copy(1)
		while cursor.valid:
			if cursor.stmt.depth <= depth:
				break
			cursor.index += 1
		return cursor.stmt

## The next statement in a lower depth than this one. (less nested)
var next_lower_depth : Stmt :
	get:
		var cursor := address.copy(1)
		while cursor.valid:
			if cursor.stmt.depth < depth:
				break
			cursor.index += 1
		return cursor.stmt

## Previous statement in the exact same depth as this one. If we ever exit this depth (lower), return null (start of chain).
var prev_in_chain : Stmt :
	get:
		var cursor := address.copy(-1)
		while cursor.valid:
			if cursor.stmt.depth == depth:
				break
			if cursor.stmt.depth < depth:
				return null
			cursor.index -= 1
		return cursor.stmt

## The previous statement in the same depth (or lower) as this one.
var prev_in_depth : Stmt :
	get:
		var cursor := address.copy(-1)
		while cursor.valid:
			if cursor.stmt.depth <= depth:
				break
			cursor.index -= 1
		return cursor.stmt

# ## The next statement in a higher depth than this one. (more nested)
# var next_higher_depth : Stmt :
# 	get:
# 		var cursor := address.copy(1)
# 		while cursor.valid:
# 			if cursor.stmt.depth > depth:
# 				break
# 			cursor.index += 1
# 		return cursor.stmt

var reconstructed_string : String :
	get:
		var result := ""
		for i in tokens:
			result += str(i.value) + " "
		result = result.substr(0, result.length() - 1)
		return "%s %s" % [_get_keyword(), result]

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
func _get_verbosity() -> int:
	return -1

## Executes just once, as soon as all scripts have been validated.
func _load() -> PennyException:
	return null

## Executes when it is reached as the user encounters it.
func _execute(host: PennyHost) -> Record:
	return Record.new(host, self)

## Executes when the user rewinds through history to undo this action.
func _undo(record: Record) -> void:
	pass

## Returns the address of the next statement to go to, based on what happened.
func _next(record: Record) -> Stmt:
	return next_in_order

## Creates a message to be shown in the statement history or displayed to a dialogue box.
func _message(record: Record) -> Message:
	return Message.new(reconstructed_string)

## Returns an exception to check what may be wrong with the statement (or null if OK)
func _validate() -> PennyException:
	return create_exception("_validate() method needs to be overridden and/or statement was never recycled into the proper type (not implemented).")

func create_exception(s: String = "Uncaught exception.") -> PennyException:
	return PennyExceptionRef.new(file_address, s)

func recycle() -> Stmt:
	if tokens.is_empty():
		create_exception("Empty statement.")
	match tokens[0].type:
		Token.VALUE_STRING:
			return StmtMessage.new(address, line, depth, tokens)
		Token.KEYWORD:
			var key = tokens.pop_front().value
			match key:
				'pass': return StmtPass.new(address, line, depth, tokens)
				'print': return StmtPrint.new(address, line, depth, tokens)
				'label', 'jump': return StmtLabel.new(address, line, depth, tokens)
				'if': return StmtConditionalIf.new(address, line, depth, tokens)
				'elif': return StmtConditionalElif.new(address, line, depth, tokens)
				'else': return StmtConditionalElse.new(address, line, depth, tokens)
		Token.IDENTIFIER:
			if tokens.size() == 1:
				pass
				# throw exception for now, this will become object manipulation
			else:
				return StmtAssign.new(address, line, depth, tokens)
	return self

func validate_as_no_tokens() -> PennyException:
	if not tokens.is_empty():
		return create_exception("Unexpected token(s) in standalone statement.")
	return null

func validate_as_identifier_only() -> PennyException:
	if tokens.size() != 1:
		return create_exception("Statement requires exactly 1 token.")
	if tokens[0].type != Token.IDENTIFIER:
		return create_exception("Unexpected token '%s' is not an identifier." % tokens[0])
	return null

func validate_as_expression(require: bool = true) -> PennyException:
	if not require and tokens.is_empty():
		return null
	return validate_expression(tokens)

func validate_expression(expr: Array[Token]) -> PennyException:
	if expr.is_empty():
		return create_exception("Expression is empty.")
	return null
