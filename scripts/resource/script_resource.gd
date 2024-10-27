
class_name PennyScriptResource extends Resource

@export var id : int
# @export_storage var id : int
@export var content : String

func _init(_id: int, _content: String) -> void:
	id = _id
	content = _content

