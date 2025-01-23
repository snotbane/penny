
## No description
class_name StmtMenu extends StmtOpen


var nested_option_stmts : Array[StmtConditionalMenu]
var response : Variant :
	get:
		return subject.get_value(&"response")


func _get_is_rollable() -> bool:
	return true


func _get_is_skippable() -> bool:
	return false


func _reload() -> void:
	super._reload()
	for stmt in self.nested_stmts_single_depth:
		if stmt is StmtConditionalMenu:
			nested_option_stmts.push_back(stmt)


func _execute(host: PennyHost) :
	host.expecting_conditional = true

	var prompt_options : Array = subject.get_value(&"options")
	prompt_options.clear()

	var i := -1
	for stmt in nested_option_stmts:
		i += 1
		var key : StringName
		var option : Cell
		if stmt.is_raw_text_option:
			key = "_" + str(i)
			option = Cell.new(key, Cell.ROOT, {
				&"base": Cell.Ref.new([&"option"], false),
				&"name": stmt.expr.evaluate()
			})
		else:
			option = stmt.expr.evaluate()
			key = option.self_key
		Cell.ROOT.set_value(key, option)
		prompt_options.push_back(Cell.Ref.new([key], false))

	var data := { "before": subject.get_value(&"response") }

	await super._execute(host)
	await subject_node.advanced

	data["after"] = subject.get_value(&"response")

	return self.create_record(host, data)


func _undo(record: Record) -> void:
	super._undo(record)
	subject.set_value(&"response", record.data["before"])


func _redo(record: Record) -> void:
	super._redo(record)
	subject.set_value(&"response", record.data["after"])


func _get_default_subject() -> Cell.Ref:
	return Cell.Ref.new([&"prompt"], false)
