
## Record of a stmt that has occurred. Records that share the same stmt are not necessarily equal as they can have occurred at different stamps (times).
class_name Record extends Object

enum Response {
	IGNORE,
	RECORD_ONLY,
	RECORD_AND_ADVANCE
}

var host : PennyHost
var stamp : int
var stmt : Stmt
var data : Variant
var response : Response

var verbosity : int :
	get: return stmt.verbosity


var prev : Record :
	get:
		if stamp == 0 : return null
		return host.history.records[stamp - 1]


var is_recorded : bool :
	get: return response >= Response.RECORD_ONLY

var is_advanced : bool :
	get: return response == Response.RECORD_AND_ADVANCE


func _init(_host: PennyHost, _stmt: Stmt, _data: Variant = null, _response := Response.RECORD_AND_ADVANCE) -> void:
	host = _host
	stamp = host.history.records.size()
	stmt = _stmt
	data = _data
	response = _response


func undo() -> void:
	stmt.undo(self)


func redo() -> void:
	stmt.redo(self)


func _to_string() -> String:
	return "Record : stamp %s" % [stamp]


func equals(other: Record) -> bool:
	return host == other.host and stamp == other.stamp


func next() -> Stmt:
	return stmt.next(self)


func create_history_listing() -> HistoryListing:
	return stmt.create_history_listing(self)
