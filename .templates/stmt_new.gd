
## No description
class_name StmtNew extends Stmt

func _init(_address: Address, _line: int, _depth: int, _tokens: Array[Token]) -> void:
	super._init(_address, _line, _depth, _tokens)

func _get_is_halting() -> bool:
	return super._get_is_halting()

func _get_keyword() -> StringName:
	return super._get_keyword()

func _get_verbosity() -> int:
	return super._get_verbosity()

# func _load() -> void:
# 	super._load()

func _execute(host: PennyHost) -> Record:
	return super._execute(host)

# func _undo(record: Record) -> void:
# 	super._undo(record)

func _message(record: Record) -> Message:
	return super._message(record)

func _validate() -> PennyException:
	return super._validate()
