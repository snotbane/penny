## Stores one or more of its values in a JSON-style dictionary.
class_name JSONResource extends Resource

func export_json() -> Dictionary:
	var result := {}
	_export_json(result)
	return result
func _export_json(json: Dictionary) -> void: pass


func import_json(json: Dictionary) -> void:
	_import_json(json)
func _import_json(json: Dictionary) -> void: pass
