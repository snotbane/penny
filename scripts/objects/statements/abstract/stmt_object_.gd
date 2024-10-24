
## Statement that interacts with an object and can have nested statements that interact with said object.
class_name StmtObject_ extends Stmt_

var path : Path

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)

# func _get_is_halting() -> bool:
# 	return super._get_is_halting()

func _get_keyword() -> StringName:
	return 'object_head'

func _get_verbosity() -> Verbosity:
	return Verbosity.DATA_ACTIVITY

# func _is_record_shown_in_history(record: Record) -> bool:
# 	return true

# func _load() -> PennyException:
# 	super._load()

func _execute(host: PennyHost) -> Record:
	var before : Variant = path.evaluate(host.data_root)
	if before: return super._execute(host)
	var after : Variant = self.get_context_parent(host).add_object(path.ids.back(), PennyObject.DEFAULT_BASE)
	if after is PennyObject:
		after.self_key = path.ids.back()
	print(after.rich_name)
	return create_record(host, before, after)

func get_context_object(host: PennyHost) -> PennyObject:
	return self.get_value_from_path(host.data_root, path)

func get_context_parent(host: PennyHost) -> PennyObject:
	var parent_path := path.duplicate()
	parent_path.ids.pop_back()
	var result : PennyObject = get_nested_object(host.data_root)
	if result: return result
	return host.data_root

func create_record(host: PennyHost, before: Variant, after: Variant) -> Record:
	var result = Record.new(host, self, AssignmentRecord.new(before, after))
	host.on_data_modified.emit()
	return result

func _undo(record: Record) -> void:
	if record.attachment:
		path.set_data(record.host, record.attachment.before)

func _message(record: Record) -> Message:
	var result := Message.new("[color=#%s][code]%s[/code][/color]" % [Penny.IDENTIFIER_COLOR.to_html(), path])
	if record.attachment:
		result.append(" = %s" % record.attachment)
	return result


func _validate() -> PennyException:
	var exception := validate_path(tokens)
	if exception:
		return exception

	path = Path.from_tokens(tokens)
	return null
