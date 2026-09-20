@abstract
@tool
class_name StmtExpress
extends Stmt

@export_storage
var express: Variant


func _get_debug_message() -> String:
	return str(express)


func _populate(tokens: Array) -> void:
	express = Penny.Express.new_or_literal_from_tokens_destructive(tokens)


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	record.data = Penny.Evaluable.evaluate_any(express, context_value_from_recent)
