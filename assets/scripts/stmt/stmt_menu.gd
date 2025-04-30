
## No description
class_name StmtMenu extends StmtOpen

enum Mode {
	## Use this type if any [member nested_option_stmts] are found. This will use the supplied prompt cell to display the options, but the actual options used will be populated from [member nested_option_stmts].
	EXPLICIT,
	## Use this type if no [member nested_option_stmts] are found. This will use the supplied prompt cell to display the options, and the actual options will be populated from the prompt cell as well.
	CELL,
}

var mode : Mode
var nested_option_stmts : Array[StmtConditionalMenu]
var response : Variant :
	get:
		return subject.get_value(Cell.K_RESPONSE)


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY


func _get_is_rollable() -> bool:
	return true


func _get_is_skippable() -> bool:
	return false


func _populate(tokens: Array) -> void:
	super._populate(tokens)
	if tokens.is_empty():
		local_subject_ref = Cell.Ref.new([ Cell.K_PROMPT ], false)


func _reload() -> void:
	super._reload()
	for stmt in self.get_nested_stmts_single_depth():
		if stmt is StmtConditionalMenu:
			nested_option_stmts.push_back(stmt)
	mode = Mode.CELL if nested_option_stmts.is_empty() else Mode.EXPLICIT


func _execute(host: PennyHost) :
	host.expecting_conditional = true

	match mode:
		Mode.EXPLICIT:
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
					key = option.key_name
				Cell.ROOT.set_value(key, option)
				prompt_option_refs.push_back(Cell.Ref.new([key], false))
			subject.set_value(Cell.K_OPTIONS, prompt_option_refs)


	var data : Dictionary[StringName, Variant] = { &"prior": subject.get_value(Cell.K_RESPONSE) }

	await super._execute(host)
	await subject_node.advanced

	data[&"after"] = subject.get_value(Cell.K_RESPONSE)

	match mode:
		Mode.CELL:
			host.call_stack.push_back(next_in_order)

	return self.create_record(host, data)


func _undo(record: Record) -> void:
	match mode:
		Mode.CELL:
			record.host.call_stack.pop_back()
	super._undo(record)
	subject.set_value(Cell.K_RESPONSE, record.data[&"prior"])


func _redo(record: Record) -> void:
	match mode:
		Mode.CELL:
			record.host.call_stack.push_back(next_in_order)
	super._redo(record)
	subject.set_value(Cell.K_RESPONSE, record.data[&"after"])


func _next(record: Record) -> Stmt:
	match mode:
		Mode.CELL:
			return Penny.get_stmt_from_label(record.data[&"after"].evaluate().get_value(&"jump"))
	return super._next(record)



func _get_default_subject() -> Cell.Ref:
	return Cell.Ref.new([Cell.K_PROMPT], false)


func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]menu : [/color]%s[/code]" % Penny.get_value_as_bbcode_string(subject)
