## Stores a sequence of Penny commands.
class_name History extends JSONResource

signal record_added(record : Record)
signal record_removed(record : Record)


var records : Array[Record]
var max_size : int = -1


var most_recent : Record :
	get: return records.back()

var last_dialog : Record :
	get:
		for i in records.size():
			if records[-i-1].stmt is StmtDialog:
				return records[-i-1]
		return null

var back_index : int :
	get : return records.size() - 1


func _get_path_ext() -> String:
	return ".sav"


func populate_host(host: PennyHost) -> void:
	for record in records:
		record.host = host


func _init(_max_size : int = -1) -> void:
	max_size = _max_size


func add(record: Record) -> void:
	if max_size >= 0: while records.size() >= max_size:
		record_removed.emit(records.pop_front())

	records.push_back(record)
	record_added.emit(record)


func cull_ahead(index: int) -> void:
	for i in back_index - index:
		record_removed.emit(records.pop_back())

func cull_behind(index: int) -> void:
	var start := records.slice(0, index)
	records = records.slice(0)
	for record in start:
		record_removed.emit(record)


func get_roll_back_index(from: int) -> int:
	while from > 0:
		from -= 1
		if records[from].stmt.is_rollable_back: return from
	return -1

func get_roll_ahead_index(from: int) -> int:
	while from < back_index:
		from += 1
		if records[from].stmt.is_rollable_ahead: return from
	return -1


func _export_json(json: Dictionary) -> void:
	var record_data : Array
	for record in records: record_data.push_back(record.export_json())

	json.merge({
		&"records": record_data
	})

func _import_json(json: Dictionary) -> void:
	records.clear()
	for record in json[&"records"]:
		records.push_back(Record.new(
			json[&"__host__"],
			Penny.get_stmt_from_uid(
				record[&"stmt"][&"uid"],
				record[&"stmt"][&"idx"]
			),
			record[&"data"],
			Record.Response.IGNORE
		))
