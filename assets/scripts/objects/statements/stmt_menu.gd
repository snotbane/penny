
## No description
class_name StmtMenu extends StmtOpen

var nested_option_stmts : Array[StmtConditionalMenu]


var response : Variant :
	get:
		return subject.get_value(PennyObject.RESPONSE_KEY)


# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'menu'


# func _get_verbosity() -> Verbosity:
# 	return super._get_verbosity()


func _get_is_rollable() -> bool:
	return true


func _get_is_skippable() -> bool:
	return false


# func _validate_self() -> PennyException:
# 	return create_exception("Statement was registered/recognized, but _validate_self() was not overridden!")


func _validate_self_post_setup() -> void:
	super._validate_self_post_setup()
	for stmt in self.nested_stmts_single_depth:
		if stmt is StmtConditionalMenu:
			nested_option_stmts.push_back(stmt)


# func _validate_cross() -> PennyException:
# 	return super._validate_cross()


func _execute(host: PennyHost) :
	host.expecting_conditional = true

	var prompt_options : Array = subject.get_value(PennyObject.OPTIONS_KEY)
	prompt_options.clear()

	var i := -1
	for stmt in nested_option_stmts:
		i += 1
		var key : StringName
		var option : PennyObject
		if stmt.is_raw_text_option:
			key = "_" + str(i)
			option = PennyObject.new(key, PennyObject.STATIC_ROOT, {
				PennyObject.BASE_KEY: Path.new_from_single(PennyObject.BILTIN_OPTION_NAME),
				PennyObject.NAME_KEY: stmt.expr.evaluate()
			})
		else:
			option = stmt.expr.evaluate()
			key = option.self_key
		PennyObject.STATIC_ROOT.set_value(key, option)
		prompt_options.push_back(Path.new_from_single(key))

	var data := { "before": subject.get_value(PennyObject.RESPONSE_KEY) }

	await super._execute(host)
	await subject_node.advanced

	data["after"] = subject.get_value(PennyObject.RESPONSE_KEY)

	return self.create_record(host, data)


func _undo(record: Record) -> void:
	super._undo(record)
	subject.set_value(PennyObject.RESPONSE_KEY, record.data["before"])


func _redo(record: Record) -> void:
	super._redo(record)
	subject.set_value(PennyObject.RESPONSE_KEY, record.data["after"])


# func _next(record: Record) -> Stmt:
# 	return super._next(record)


func _get_default_subject() -> Path:
	return Path.new_from_single(PennyObject.BILTIN_PROMPT_NAME)
