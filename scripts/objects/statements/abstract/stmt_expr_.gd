
## Simple statement that stores all its tokens as an expression.
class_name StmtExpr extends Stmt

var expr : Expr

# func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
# 	super._init(_address, _line, _depth, _tokens)


# func _get_keyword() -> StringName:
# 	return super._get_keyword()


# func _get_verbosity() -> Verbosity:
# 	return super._get_verbosity()


func _validate_self() -> PennyException:
	return validate_as_expression()


func _validate_self_post_setup() -> void:
	expr = Expr.from_tokens(tokens, self)


# func _validate_cross() -> PennyException:
# 	return null


# func _execute(host: PennyHost) -> Record:
# 	return super._execute(host)


# func _undo(record: Record) -> void:
# 	pass


# func _next(record: Record) -> Stmt:
# 	return next_in_order
