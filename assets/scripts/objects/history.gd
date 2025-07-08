## Stores a sequence of Penny commands.
class_name History extends JSONResource

signal record_added(record : Record)
signal record_removed(record : Record)


var records : Array[Record]
var max_size : int = -1


var most_recent : Record :
	get: return records.front()


var last_dialog : Record :
	get:
		for record in records:
			if record.stmt is StmtDialog:
				return record
		return null


func _get_path_ext() -> String:
	return ".sav"


func populate_host(host: PennyHost) -> void:
	for record in records:
		record.host = host


func _init(_max_size : int = -1) -> void:
	max_size = _max_size


func add(record: Record) -> void:
	if max_size >= 0:
		while records.size() >= max_size:
			record_removed.emit(records.pop_back())

	records.push_front(record)
	record_added.emit(record)


func reset_at(index : int) -> void:
	index += 1
	for i in index:
		record_removed.emit(records.pop_front())


func get_roll_back_point(from: int) -> int:
	while from < records.size() - 1:
		from += 1
		if records[from].stmt.is_rollable: return from
	return -1


func get_roll_ahead_point(from: int) -> int:
	while from > 0:
		from -= 1
		if records[from].stmt.is_rollable: return from
	return -1



func get_reverse_index(i: int) -> int:
	return records.size() - i - 1


func _export_json(json: Dictionary) -> void:
	var copy := records.duplicate()
	copy.reverse()
	json.merge({
		&"records": copy.map(func(record: Record):
			return record.export_json()
			),
	})

func _import_json(json: Dictionary) -> void:
	records.clear()
	for record in json[&"records"]:
		## Host used to be set here directly via dependency injection. However, since we made History a [JSONResource], this was removed. If you're getting null/nil errors, be sure to call populate_host immediately after import_json.
		records.push_front(Record.new(null, Penny.get_stmt_from_address(record[&"stmt"][&"script"], record[&"stmt"][&"index"]), Load.any(record[&"data"]), Record.Response.IGNORE))
