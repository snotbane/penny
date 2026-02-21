## Record of a [Stmt] that has occurred. Records that share the same [Stmt] are not necessarily equal as they can have occurred at different stamps (times).
class_name Record extends JSONResource

var host : PennyHost
var stamp : int
var stmt : Stmt
var data : Dictionary
var force_cull_history : bool = false

var verbosity : int :
	get: return stmt.verbosity


var prev : Record :
	get:
		if stamp == 0 : return null
		return host.history.records[stamp - 1]


func _init(_host: PennyHost, _stmt: Stmt, _data: Dictionary = {}) -> void:
	host = _host
	stamp = host.history.records.size()
	stmt = _stmt
	data = _data


func undo() -> void:
	stmt.undo(self)


func redo() -> void:
	stmt.redo(self)


func _to_string() -> String:
	return "Record : %s\n       : %s" % [ stmt.__debug_string__, data]


func equals(other: Record) -> bool:
	return host == other.host and stamp == other.stamp


func next() -> Stmt:
	return stmt.next(self)


func create_history_listing() -> HistoryListing:
	return stmt.create_history_listing(self)


func _export_json(json: Dictionary) -> void:
	json.merge({
		&"stmt": stmt.export_json(),
		&"data": stmt.serialize_record(self),
	})

func _import_json(json: Dictionary) -> void:
	stmt = Penny.get_stmt_from_uid(
		json[&"stmt"][&"uid"],
		json[&"stmt"][&"idx"]
	)
	data = stmt.deserialize_record(self, json[&"data"])
