
@tool
class_name PennyScriptResource extends Resource

@export_storage var id : int
@export_storage var stmts : Array[Stmt_]
# @export_storage var content : String


func _init() -> void:
	pass


func update_from_file(file: FileAccess) -> void:
	var parser := PennyParser.from_file(file)
	parser.parse_tokens()
	parser.parse_statements(self)

	stmts = parser.stmts


func validate() -> Array[PennyException]:
	return []


