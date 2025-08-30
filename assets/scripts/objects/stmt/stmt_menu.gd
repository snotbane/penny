## Defines a menu for the player to choose which branch they wish to execute.
class_name StmtMenu extends StmtNode

enum Mode {
	## Use this type if any [member nested_option_stmts] are found. This will use the supplied prompt cell to display the options, but the actual options used will be populated from [member nested_option_stmts].
	EXPLICIT,
	## Use this type if no [member nested_option_stmts] are found. This will use the supplied prompt cell to display the options, and the actual options will be populated from the prompt cell as well.
	CELL,
}

var mode : Mode
var nested_option_stmts : Array[StmtConditionalMenu]
var response : Path :
	get: return subject.get_value(Cell.K_RESPONSE)


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY

func _get_is_rollable_back() -> bool:
	return false

func _get_is_rollable_ahead() -> bool:
	return true

func _get_is_skippable() -> bool:
	return false

func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]menu : [/color]%s[/code]" % Penny.get_value_as_bbcode_string(subject)


func _init() -> void:
	super._init(StorageQualifier.NONE)

func _populate(tokens: Array) -> void:
	super._populate(tokens)
	if subject == Cell.ROOT:
		local_subject_ref = Path.new([ Cell.K_PROMPT ], false)

func _reload() -> void:
	super._reload()
	if self.get_next_in_order().depth > self.depth:
		for stmt in self.get_nested_stmts_single_depth():
			if stmt is not StmtConditionalMenu: continue
			nested_option_stmts.push_back(stmt)

	mode = Mode.CELL if nested_option_stmts.is_empty() else Mode.EXPLICIT

func _prep(record: Record) -> void:
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
						Cell.K_PROTOTYPE: Path.new([Cell.K_OPTION], false),
						Cell.K_TEXT: stmt.expr.evaluate()
					})
				else:
					option = stmt.expr.evaluate()
					key = option.key_name
				Cell.ROOT.set_value(key, option)
				Cell.ROOT.set_key_stored(key, true)
				prompt_option_refs.push_back(Path.new([key], false))
			subject.set_value(Cell.K_OPTIONS, prompt_option_refs)
		# Mode.CELL:
		# 	record.host.call_stack.push_back(next_in_order)

	record.data.merge({
		&"prior": response,
		&"prior_consumed": (response.evaluate().get_value(Cell.K_CONSUMED)) if response else false
	})

func _execute(record: Record) :
	await subject.enter(Funx.new(record.host, true))
	await subject_node.advanced

	record.force_cull_history = record.data.get(&"after") != response
	record.data[&"after"] = response
	record.data[&"after_consumed"] = (response.evaluate().get_value(Cell.K_CONSUMED)) if response else false

	record.host.expecting_conditional = record.force_cull_history and mode == Mode.EXPLICIT

func _cleanup(record: Record) :
	await subject.exit(Funx.new(record.host, true))

func _undo(record: Record) -> void:
	super._undo(record)
	subject.set_value(Cell.K_RESPONSE, record.data[&"prior"])
	if record.data[&"after"] == null: return
	record.data[&"after"].evaluate().set_value(Cell.K_CONSUMED, record.data[&"prior_consumed"])

func _redo(record: Record) -> void:
	super._redo(record)
	subject.set_value(Cell.K_RESPONSE, record.data[&"after"])
	if record.data[&"after"] == null: return
	record.data[&"after"].evaluate().set_value(Cell.K_CONSUMED, record.data[&"after_consumed"])

# func _next(record: Record) -> Stmt:
# 	match mode:
# 		Mode.CELL:
# 			return Penny.get_stmt_from_label(record.data[&"after"].evaluate().get_value(&"jump"))
# 	return super._next(record)


func _get_default_subject() -> Path:
	return Path.new([Cell.K_PROMPT], false)
