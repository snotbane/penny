
## No description
class_name StmtMenu extends StmtOpen


var nested_option_stmts : Array[StmtConditionalMenu]
var response : Variant :
	get:
		return subject.get_value(Cell.K_RESPONSE)


func _get_is_rollable() -> bool:
	return true


func _get_is_skippable() -> bool:
	return false


func _populate(tokens: Array) -> void:
	super._populate(tokens)
	if tokens.is_empty():
		subject_ref = Cell.Ref.new([ Cell.K_PROMPT ], false)


func _reload() -> void:
	super._reload()
	for stmt in self.get_nested_stmts_single_depth():
		if stmt is StmtConditionalMenu:
			nested_option_stmts.push_back(stmt)


func _execute(host: PennyHost) :
	host.expecting_conditional = true

	var prompt_option_refs : Array

	var i := -1
	for stmt in nested_option_stmts:
		i += 1
		var key : StringName
		var option : Cell
		if stmt.is_raw_text_option:
			key = "_" + str(i)
			option = Cell.new(key, Cell.ROOT, {
				Cell.K_BASE: Cell.Ref.new([Cell.K_OPTION], false),
				Cell.K_TEXT: stmt.expr.evaluate()
			})
		else:
			option = stmt.expr.evaluate()
			key = option.self_key
		Cell.ROOT.set_value(key, option)
		prompt_option_refs.push_back(Cell.Ref.new([key], false))

	subject.set_value(Cell.K_OPTIONS, prompt_option_refs)

	var data := { "before": subject.get_value(Cell.K_RESPONSE) }

	await super._execute(host)
	await subject_node.advanced

	data["after"] = subject.get_value(Cell.K_RESPONSE)

	return self.create_record(host, data)


func _undo(record: Record) -> void:
	super._undo(record)
	subject.set_value(Cell.K_RESPONSE, record.data["before"])


func _redo(record: Record) -> void:
	super._redo(record)
	subject.set_value(Cell.K_RESPONSE, record.data["after"])


func _get_default_subject() -> Cell.Ref:
	return Cell.Ref.new([Cell.K_PROMPT], false)
