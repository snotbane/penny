
## Statement that interacts with an object and can have nested statements that interact with said object.
class_name StmtObject extends Stmt

var path : Path


# func _init() -> void:
# 	pass


func _get_keyword() -> StringName:
	return 'object_head'


func _get_verbosity() -> Verbosity:
	return Verbosity.DATA_ACTIVITY


func _validate_self() -> PennyException:
	var exception := validate_path(tokens)
	if exception:
		return exception

	path = Path.new_from_tokens(tokens)
	return null


# func _validate_cross() -> PennyException:
# 	super._validate_cross()


func _execute(host: PennyHost) :
	var prior : Variant = path.evaluate_shallow()
	if prior: return super._execute(host)
	var after : Variant = self.owning_object.add_object(path.ids.back(), PennyObject.DEFAULT_BASE)
	if after is PennyObject:
		after.self_key = path.ids.back()
	print("StmtObject: ", after.rich_name)
	return create_assignment_record(host, prior, after)


func _undo(record: Record) -> void:
	path.set_value_for(owning_object, record.data["before"])


func _redo(record: Record) -> void:
	path.set_value_for(owning_object, record.data["after"])


# func _next(record: Record) -> Stmt:
# 	return next_in_order


func _create_history_listing(record: Record) -> HistoryListing:
	var result := super._create_history_listing(record)
	result.message_label.text = "[color=#%s][code]%s[/code][/color]" % [Penny.IDENTIFIER_COLOR.to_html(), path]
	if record.data:
		result.message_label.text += " = %s" % record.data
	return result


func create_assignment_record(host: PennyHost, before: Variant, after: Variant) -> Record:
	var result := create_record(host, { "before": before, "after": after })
	host.on_data_modified.emit()
	return result



static func assignment_to_string(record: Record) -> String:
	return " [color=#%s][code]%s[/code][/color]  \u2b60  [code]%s[/code]" % [Penny.FUTURE_COLOR.to_html(), Penny.get_debug_string(record.data["after"]), Penny.get_debug_string(record.data["before"])]
