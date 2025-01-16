
class_name Cell extends RefCounted

class Ref:
	const COLOR := Color8(65, 122, 236)

	var ids : PackedStringArray
	var rel : bool

	func _init(path_string: String) -> void:
		rel = path_string[1] == "."
		path_string = path_string.substr(1 if rel else 0)
		ids = path_string.split(".", false)


	static func to(cell: Cell, _rel: bool = false) -> Ref:
		var path_string := cell.key_name
		var cursor := cell.parent
		while cursor:
			path_string = cursor.key_name + "." + path_string
			cursor = cursor.parent
		if _rel: path_string = "." + path_string
		return Ref.new(path_string)


	func _to_string() -> String:
		var result := "." if rel else ""
		for id in ids:
			result += id + "."
		return "/" + result.substr(0, result.length() - 1)

static var ROOT := Cell.new(&"", null, {})

static var OBJECT := Cell.new(&"object", ROOT, {
	&"base": null,
	&"dialog": &"dialog",
	&"name": "",
	&"name_prefix": "<>",
	&"name_suffix": "</>",
})
static var DIALOG := Cell.new(&"dialog", ROOT, {
	&"base": Ref.to(OBJECT),
	# &"link": Lookup.new(&"dialog_default"),
	&"link_layer": 0,
})
static var PROMPT := Cell.new(&"prompt", ROOT, {
	&"base": Ref.new("object"),
	# &"link": Lookup.new(&"prompt_default"),
	&"options": [],
	&"response": null,
})
static var OPTION := Cell.new(&"option", ROOT, {
	&"base": Ref.new("object"),
	&"enabled": true,
	&"visible": true,
	&"consumed": false
})


var key_name : StringName
var parent : Cell
var data : Variant


func _init(_key_name : StringName, _parent : Cell, _data : Variant) -> void:
	key_name = _key_name
	parent = _parent
	data = _data

	if parent:
		if parent.data is not Dictionary:
			printerr("Cell %s: Attempted to add this cell to parent %s, but is not a Dictionary.")
		else:
			parent.data[key_name] = self


func _to_string() -> String:
	return "@" + key_name


func get_data(path_string: String) -> Variant:
	var path := Ref.new(path_string)
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

