
## Statement that interacts with an object and can have nested statements that interact with said object.
class_name StmtObject_ extends Stmt_

var obj_path : Path

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)

# func _get_is_halting() -> bool:
# 	return super._get_is_halting()

func _get_keyword() -> StringName:
	return 'object'

func _get_verbosity() -> Verbosity:
	return Verbosity.IGNORED

# func _is_record_shown_in_history(record: Record) -> bool:
# 	return true

# func _load() -> PennyException:
# 	super._load()

# func _execute(host: PennyHost) -> Record:
# 	return super._execute(host)

# func _undo(record: Record) -> void:
# 	super._undo(record)

func _message(record: Record) -> Message:
	return Message.new("[color=#%s][code]%s[/code][/color]" % [Penny.IDENTIFIER_COLOR.to_html(), obj_path])

func _validate() -> PennyException:
	var exception := validate_obj_path(tokens)
	if exception:
		return exception

	obj_path = Path.from_tokens(tokens)
	return null

func _setup() -> void:
	if prev_lower_depth is StmtObject_:
		obj_path.prepend(prev_lower_depth.obj_path)
