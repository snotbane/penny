## Simple statement that stores all its tokens as an expression.
class_name StmtExpr extends Stmt

var expr : Expr


func _populate(tokens: Array) -> void:
	expr = Expr.new_from_tokens(tokens)
