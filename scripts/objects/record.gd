
## Record of a stmt that has occurred. Records that share the same stmt are not necessarily equal as they can have occurred at different stamps (times).
class_name Record extends Object

var host : PennyHost
var stamp : int
var stmt : Stmt_
var message : Message
var attachment : Variant

var verbosity : int :
	get: return stmt._get_verbosity()

var prev : Record :
	get:
		if stamp == 0 : return null
		return host.records[stamp - 1]

func _init(_host: PennyHost, _stmt: Stmt_, _attachment: Variant = null) -> void:
	host = _host
	stamp = host.records.size()
	stmt = _stmt
	attachment = _attachment
	message = stmt._message(self)

func undo() -> void:
	stmt._undo(self)

func _to_string() -> String:
	return "Record : stamp %s, address %s" % [stamp, stmt.address]

func equals(other: Record) -> bool:
	return host == other.host and stamp == other.stamp

func get_next() -> Stmt_:
	return stmt._next(self)
