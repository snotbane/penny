
@tool
class_name PennyScript extends Resource

static var LINE_FEED_REGEX := RegEx.create_from_string("\\n")

@export_storage var id : int
@export_storage var stmts : Array[Stmt] = []

func _init(path : String) -> void:
	id = hash(path)


func update_from_file(file: FileAccess) -> void:
	pass


func parse_and_register_stmts(tokens: Array, context_file: FileAccess) -> void:
	pass

static func parse_tokens_from_raw(raw: String, context_file: FileAccess = null) -> Array:
	return []
