
class_name Cell extends RefCounted

static var ROOT := Cell.new(&"", null, {})

static var OBJECT := Cell.new(&"object", ROOT, {
	&"base": null,
	&"dialog": "dialog",
	&"name": "",
	&"name_prefix": "<>",
	&"name_suffix": "</>",
})
static var DIALOG := Cell.new(&"dialog", ROOT, {
	&"base": "object",
	&"link": Lookup.new(&"dialog_default"),
	&"link_layer": 0,
})
static var PROMPT := Cell.new(&"prompt", ROOT, {
	&"base": "object",
	&"link": Lookup.new(&"prompt_default"),
	&"options": [],
	&"response": null,
})
static var OPTION := Cell.new(&"option", ROOT, {
	&"base": "object",
	&"enabled": true,
	&"visible": true,
	&"consumed": false
})

class CellPath:
	var ids : PackedStringArray
	var rel : bool

	func _init(path_string: String) -> void:
		rel = path_string[1] == "."
		path_string = path_string.substr(2 if rel else 1)
		ids = path_string.split(".", false)


	func _to_string() -> String:
		var result := "." if rel else ""
		for id in ids:
			result += id + "."
		return result.substr(0, result.length() - 1)


var id : StringName
var parent : Cell
var data : Variant

func _init(_id : StringName, _parent : Cell, _data : Variant) -> void:
	id = _id
	parent = _parent
	data = _data
	
	parent.data[id] = self


func _to_string() -> String:
	return "@" + id


func get_data_from_path(path_string: String) -> Variant:
	var path := CellPath.new(path_string)
	var cursor : Variant = self if path.rel else ROOT
	for i in path.ids:
		if cursor is not Cell:
			printerr("Cell %s: Attempted to evaluate path %s, but '%s' is not a Cell." % [self, path, i])
			return null
		
		if not cursor.data.has(i):
			printerr("Cell %s: Attempted to evaluate path %s, but cell data '%s' does not exist in Dictionary." % [self, path, i])
			return null
			
		cursor = data[i]
	return cursor

