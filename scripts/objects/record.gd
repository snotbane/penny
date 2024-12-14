
## Record of a stmt that has occurred. Records that share the same stmt are not necessarily equal as they can have occurred at different stamps (times).
class_name Record extends Object

var host : PennyHost
var stamp : int
var stmt : Stmt
var aborted : bool
var attachment : Variant

var verbosity : int :
	get: return stmt.verbosity


var prev : Record :
	get:
		if stamp == 0 : return null
		return host.history.records[stamp - 1]


func _init(_host: PennyHost, _stmt: Stmt, _aborted : bool = false, _attachment: Variant = null) -> void:
	host = _host
	stamp = host.history.records.size()
	stmt = _stmt
	aborted = _aborted
	attachment = _attachment


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
