
@tool
class_name PennyScript extends Resource

static var LINE_FEED_REGEX := RegEx.create_from_string("\\n")

@export_storage var id : int
@export_storage var stmts : Array[Stmt] = []
@export_storage var errors : Array[String] = []

func _init(path : String) -> void:
	id = hash(path)


func update_from_file(file: FileAccess) -> void:
	pass
