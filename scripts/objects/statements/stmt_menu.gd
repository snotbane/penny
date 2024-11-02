
## No description
class_name StmtMenu extends StmtOpen

var nested_option_stmts : Array[StmtConditionalMenu]

# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'menu'


# func _get_verbosity() -> Verbosity:
# 	return super._get_verbosity()


# func _validate_self() -> PennyException:
# 	return create_exception("Statement was registered/recognized, but _validate_self() was not overridden!")


func _validate_self_post_setup() -> void:
	super._validate_self_post_setup()
	for stmt in self.nested_stmts_single_depth:
		if stmt is StmtConditionalMenu:
			nested_option_stmts.push_back(stmt)
	for i in nested_option_stmts.size():
		nested_option_stmts[i].menu_stmt = self
		nested_option_stmts[i].expected_path = Path.from_single('_' + str(i))


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


func _execute(host: PennyHost) -> Record:
	host.expecting_conditional = true

	var prompt_object : PennyObject = subject_path.evaluate(host.data_root)
	var prompt_options : Array = prompt_object.get_value(PennyObject.OPTIONS_KEY)
	prompt_options.clear()

	var i := -1
	for stmt in nested_option_stmts:
		i += 1
		var key := "_" + str(i)
		var option := PennyObject.new(key, host.data_root, {
			PennyObject.BASE_KEY: Path.from_single(PennyObject.BILTIN_OPTION_NAME),
			PennyObject.NAME_KEY: stmt.expr.evaluate(host.data_root)
		})
		host.data_root.set_value(key, option)
		prompt_options.push_back(Path.from_single(key))

	return super._execute(host)


# func _undo(record: Record) -> void:
# 	super._undo(record)


# func _next(record: Record) -> Stmt_:
# 	return super._next(record)


func _message(record: Record) -> Message:
	return super._message(record)


func _get_default_subject() -> Path:
	return Path.from_single(PennyObject.BILTIN_PROMPT_NAME)


func get_response(host: PennyHost) -> Variant:
	return subject_path.evaluate(host.data_root).get_value(PennyObject.RESPONSE_KEY)
