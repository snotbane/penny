
## Statement that interacts with an object and can have nested statements that interact with said object.
class_name StmtObject_ extends Stmt_

var path : Path


func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)


func _get_keyword() -> StringName:
	return 'object_head'


func _get_verbosity() -> Verbosity:
	return Verbosity.DATA_ACTIVITY


func _validate_self() -> PennyException:
	var exception := validate_path(tokens)
	if exception:
		return exception

	path = Path.from_tokens(tokens)
	return null


# func _validate_cross() -> PennyException:
# 	super._validate_cross()


func _execute(host: PennyHost) -> Record:
	var prior : Variant = path.evaluate_shallow(host.data_root)
	if prior: return super._execute(host)
	var after : Variant = self.get_context_parent(host).add_object(path.ids.back(), PennyObject.DEFAULT_BASE)
	if after is PennyObject:
		after.self_key = path.ids.back()
	print(after.rich_name)
	return create_assignment_record(host, prior, after)


func _undo(record: Record) -> void:
	if record.attachment:
		path.set_data(record.host, record.attachment.before)


# func _next(record: Record) -> Stmt_:
# 	return next_in_order


func _message(record: Record) -> Message:
	var result := Message.new("[color=#%s][code]%s[/code][/color]" % [Penny.IDENTIFIER_COLOR.to_html(), path])
	if record.attachment:
		result.append(" = %s" % record.attachment)
	return result


## Returns the object that this statement is working with.
func get_context_object(host: PennyHost) -> PennyObject:
	return self.get_value_from_path_relative_to_here(host.data_root, path)


## Returns the parent of the object that this statement (primarily for setting values to it).
func get_context_parent(host: PennyHost) -> PennyObject:
	var parent_path := path.duplicate()
	parent_path.ids.pop_back()
	var result : PennyObject = self.get_owning_object(host.data_root)
	if result: return result
	return host.data_root


func create_assignment_record(host: PennyHost, before: Variant, after: Variant) -> Record:
	var result := create_record(host, false, AssignmentRecord.new(before, after))
	host.on_data_modified.emit()
	return result
