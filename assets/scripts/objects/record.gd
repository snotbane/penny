
## Record of a stmt that has occurred. Records that share the same stmt are not necessarily equal as they can have occurred at different stamps (times).
class_name Record extends JSONResource

enum Response {
	## Do not create a record.
	IGNORE,
	## Create a record, but do nothing else.
	RECORD_ONLY,
	## Create a record and advance to the next [Stmt].
	RECORD_AND_ADVANCE
}

var host : PennyHost
var stamp : int
var stmt : Stmt
var data : Dictionary
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


func _init(_host: PennyHost, _stmt: Stmt, _data: Dictionary = {}, _response := Response.RECORD_AND_ADVANCE) -> void:
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
	return "Record : %s\n       : %s\n       : %s" % [ stmt._debug_string_do_not_use_for_anything_else_seriously_i_mean_it, data, response]


func equals(other: Record) -> bool:
	return host == other.host and stamp == other.stamp


func next() -> Stmt:
	return stmt.next(self)


func create_history_listing() -> HistoryListing:
	return stmt.create_history_listing(self)


func _export_json(json: Dictionary) -> void:
	json.merge({
		&"data": Save.any(data, true),
		# &"response": Save.any(response),
		&"stmt": Save.any(stmt),
	})

# func _import_json(json: Dictionary) -> void:
# 	data = Load.any(json[&"data"])
# 	stmt = Penny.get_stmt_from_address(ResourceUID.id_to_text((json[&"stmt"][&"script_uid"])), json[&"stmt"][&"index"])
# 	response = Load.any(json[&"response"])
