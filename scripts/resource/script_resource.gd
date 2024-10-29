
@tool
class_name PennyScriptResource extends Resource

@export_storage var id : int
@export_storage var stmts : Array[Stmt_]
# @export_storage var content : String


func _init() -> void:
	pass


func update_from_file(file: FileAccess) -> void:
	# content = file.get_as_text()
	# id = hash(content)

	var parser := PennyParser.from_file(file)
	var errors := parser.parse_file()
	if errors:
		for error in errors:
			error.push()
	stmts = parser.stmts



