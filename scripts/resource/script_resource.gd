
class_name PennyScriptResource extends Resource

@export var id : int
# @export_storage var id : int
@export_storage var content : String
@export_multiline var content_ : String :
	get: return content

func _init() -> void: pass


func update_from_file(file: FileAccess) -> void:
	content = file.get_as_text()
	id = hash(content)


